//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Offering+JSON.swift
//
//  Created by RevenueCat Inc.
//

import Foundation

// MARK: - JSON Parsing

public extension Offering {

    /// Errors that can occur when parsing an Offering from JSON
    enum JSONParsingError: Error, LocalizedError {
        case invalidJSON
        case missingRequiredField(String)
        case invalidFieldType(String, expected: String)
        case packageParsingFailed(Error)
        case paywallParsingFailed(Error)
        case invalidURL(String)

        public var errorDescription: String? {
            switch self {
            case .invalidJSON:
                return "Invalid JSON format"
            case .missingRequiredField(let field):
                return "Missing required field: \(field)"
            case .invalidFieldType(let field, let expected):
                return "Invalid type for field '\(field)', expected: \(expected)"
            case .packageParsingFailed(let error):
                return "Failed to parse packages: \(error.localizedDescription)"
            case .paywallParsingFailed(let error):
                return "Failed to parse paywall: \(error.localizedDescription)"
            case .invalidURL(let urlString):
                return "Invalid URL: \(urlString)"
            }
        }
    }

        /// Initialize an Offering from a JSON string
    /// - Parameter jsonString: The JSON string to parse
    /// - Parameter overridePackages: Optional packages to use instead of packages from JSON
    /// - Throws: `JSONParsingError` if parsing fails
    convenience init(jsonString: String, overridePackages: [Package]? = nil) throws {
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw JSONParsingError.invalidJSON
        }
        
        try self.init(jsonData: jsonData, overridePackages: overridePackages)
    }

        /// Initialize an Offering from JSON data
    /// - Parameter jsonData: The JSON data to parse
    /// - Parameter overridePackages: Optional packages to use instead of packages from JSON
    /// - Throws: `JSONParsingError` if parsing fails
    convenience init(jsonData: Data, overridePackages: [Package]? = nil) throws {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: jsonData),
              let dictionary = jsonObject as? [String: Any] else {
            throw JSONParsingError.invalidJSON
        }
        
        try self.init(json: dictionary, overridePackages: overridePackages)
    }

    /// Initialize an Offering from a JSON dictionary
    /// - Parameter json: The JSON dictionary to parse
    /// - Parameter overridePackages: Optional packages to use instead of packages from JSON
    /// - Throws: `JSONParsingError` if parsing fails
    convenience init(json: [String: Any], overridePackages: [Package]? = nil) throws {
        // Parse required fields
        guard let identifier = json["identifier"] as? String else {
            throw JSONParsingError.missingRequiredField("identifier")
        }

        guard let serverDescription = json["server_description"] as? String ??
                                    json["serverDescription"] as? String ??
                                    json["description"] as? String else {
            throw JSONParsingError.missingRequiredField("server_description")
        }

                // Parse optional metadata
        let metadata = json["metadata"] as? [String: Any] ?? [:]
        
        // Use override packages if provided, otherwise use empty array (JSON package parsing not fully implemented)
        let availablePackages: [Package] = overridePackages ?? []

        // Parse optional paywall using Codable
        let paywall: PaywallData?
        if let paywallJSON = json["paywall"] as? [String: Any] {
            do {
                let paywallData = try JSONSerialization.data(withJSONObject: paywallJSON)
                paywall = try JSONDecoder.default.decode(PaywallData.self, from: paywallData)
            } catch {
                throw JSONParsingError.paywallParsingFailed(error)
            }
        } else {
            paywall = nil
        }

        // Parse optional paywall components
        let paywallComponents: PaywallComponents?
        if let componentsJSON = json["paywall_components"] as? [String: Any] {
            do {
                let componentsData = try JSONSerialization.data(withJSONObject: componentsJSON)
                let paywallComponentsData = try JSONDecoder.default.decode(PaywallComponentsData.self, from: componentsData)

                // Create a minimal UIConfig since the JSON doesn't contain UI config data
                #if !os(macOS) && !os(tvOS)
                let uiConfig = UIConfig(
                    app: UIConfig.AppConfig(colors: [:], fonts: [:]),
                    localizations: [:],
                    variableConfig: UIConfig.VariableConfig(
                        variableCompatibilityMap: [:],
                        functionCompatibilityMap: [:]
                    )
                )
                #else
                let uiConfig = UIConfig()
                #endif

                paywallComponents = PaywallComponents(uiConfig: uiConfig, data: paywallComponentsData)
            } catch {
                throw JSONParsingError.paywallParsingFailed(error)
            }
        } else {
            paywallComponents = nil
        }

        // Parse optional web checkout URL
        let webCheckoutUrl: URL?
        if let urlString = json["web_checkout_url"] as? String ??
                          json["webCheckoutUrl"] as? String {
            guard let url = URL(string: urlString) else {
                throw JSONParsingError.invalidURL(urlString)
            }
            webCheckoutUrl = url
        } else {
            webCheckoutUrl = nil
        }

        // Initialize the offering
        self.init(
            identifier: identifier,
            serverDescription: serverDescription,
            metadata: metadata,
            paywall: paywall,
            paywallComponents: paywallComponents,
            availablePackages: availablePackages,
            webCheckoutUrl: webCheckoutUrl
        )
    }

    /// Convert the Offering to a JSON dictionary
    /// - Returns: A dictionary representation of the offering
    func toJSON() -> [String: Any] {
        var json: [String: Any] = [
            "identifier": identifier,
            "server_description": serverDescription,
            "metadata": metadata,
            "packages": availablePackages.map { packageToJSON($0) }
        ]

        if let paywall = paywall {
            // Use Codable encoding for PaywallData
            if let paywallData = try? JSONEncoder().encode(paywall),
               let paywallDict = try? JSONSerialization.jsonObject(with: paywallData) {
                json["paywall"] = paywallDict
            }
        }

        if let paywallComponents = paywallComponents {
            // Use Codable encoding for PaywallComponentsData
            if let componentsData = try? JSONEncoder().encode(paywallComponents.data),
               let componentsDict = try? JSONSerialization.jsonObject(with: componentsData) {
                json["paywall_components"] = componentsDict
            }
        }

        if let webCheckoutUrl = webCheckoutUrl {
            json["web_checkout_url"] = webCheckoutUrl.absoluteString
        }

        return json
    }

    /// Convert the Offering to JSON data
    /// - Parameter options: JSON writing options (default: [])
    /// - Returns: JSON data representation
    /// - Throws: Error if JSON serialization fails
    func toJSONData(options: JSONSerialization.WritingOptions = []) throws -> Data {
        let jsonObject = toJSON()
        return try JSONSerialization.data(withJSONObject: jsonObject, options: options)
    }
}

// MARK: - Private Helpers

private extension Offering {

    /// Convert a Package to a JSON dictionary
    /// - Parameter package: The package to convert
    /// - Returns: JSON dictionary representation
    func packageToJSON(_ package: Package) -> [String: Any] {
        return [
            "identifier": package.identifier,
            "package_type": package.packageType.description ?? "custom",
            "product_identifier": package.storeProduct.productIdentifier,
            "offering_identifier": package.presentedOfferingContext.offeringIdentifier
        ]
    }
}

let exampleJSON = """
    {
      "description": "Template 001",
      "identifier": "template_001",
      "metadata": null,
      "packages": [],
      "paywall_components": {
        "asset_base_url": "https://assets.pawwalls.com",
        "components_config": {
          "base": {
            "background": {
              "type": "color",
              "value": {
                "light": {
                  "type": "hex",
                  "value": "#ffffffff"
                }
              }
            },
            "stack": {
              "components": [
                {
                  "components": [
                    {
                      "fit_mode": "fill",
                      "id": "mRNnqom-8L",
                      "mask_shape": {
                        "type": "convex"
                      },
                      "name": "",
                      "size": {
                        "height": {
                          "type": "fixed",
                          "value": 360
                        },
                        "width": {
                          "type": "fill"
                        }
                      },
                      "source": {
                        "light": {
                          "heic": "https://assets.pawwalls.com/1181742_1734556334.heic",
                          "heic_low_res": "https://assets.pawwalls.com/1181742_low_res_1734556334.heic",
                          "height": 726,
                          "original": "https://assets.pawwalls.com/1181742_1734556334.png",
                          "webp": "https://assets.pawwalls.com/1181742_1734556334.webp",
                          "webp_low_res": "https://assets.pawwalls.com/1181742_low_res_1734556334.webp",
                          "width": 670
                        }
                      },
                      "type": "image"
                    },
                    {
                      "action": {
                        "type": "navigate_back"
                      },
                      "id": "xD10Wq_d0z",
                      "name": "",
                      "stack": {
                        "components": [
                          {
                            "base_url": "https://icons.pawwalls.com/icons",
                            "color": {
                              "light": {
                                "type": "hex",
                                "value": "#000000"
                              }
                            },
                            "formats": {
                              "heic": "x.heic",
                              "png": "x.png",
                              "svg": "x.svg",
                              "webp": "x.webp"
                            },
                            "icon_background": {
                              "color": {
                                "light": {
                                  "type": "hex",
                                  "value": "#ffffffff"
                                }
                              },
                              "shape": {
                                "type": "circle"
                              }
                            },
                            "icon_name": "x",
                            "id": "KhBn4svyx1",
                            "margin": {
                              "bottom": 0,
                              "leading": 0,
                              "top": 0,
                              "trailing": 0
                            },
                            "name": "",
                            "padding": {
                              "bottom": 2,
                              "leading": 2,
                              "top": 2,
                              "trailing": 2
                            },
                            "size": {
                              "height": {
                                "type": "fixed",
                                "value": 24
                              },
                              "width": {
                                "type": "fixed",
                                "value": 24
                              }
                            },
                            "type": "icon"
                          }
                        ],
                        "dimension": {
                          "alignment": "trailing",
                          "distribution": "start",
                          "type": "vertical"
                        },
                        "id": "GHIfhxIM0K",
                        "margin": {
                          "bottom": 0,
                          "leading": 0,
                          "top": 16,
                          "trailing": 16
                        },
                        "name": "",
                        "padding": {
                          "bottom": 4,
                          "leading": 4,
                          "top": 4,
                          "trailing": 4
                        },
                        "shape": {
                          "corners": {
                            "bottom_leading": 0,
                            "bottom_trailing": 0,
                            "top_leading": 0,
                            "top_trailing": 0
                          },
                          "type": "rectangle"
                        },
                        "size": {
                          "height": {
                            "type": "fit"
                          },
                          "width": {
                            "type": "fit"
                          }
                        },
                        "spacing": 0,
                        "type": "stack"
                      },
                      "type": "button"
                    }
                  ],
                  "dimension": {
                    "alignment": "top_trailing",
                    "distribution": "space_between",
                    "type": "zlayer"
                  },
                  "id": "vWuQmJUbs4",
                  "margin": {
                    "bottom": 0,
                    "leading": 0,
                    "top": 0,
                    "trailing": 0
                  },
                  "name": "Header image",
                  "padding": {
                    "bottom": 0,
                    "leading": 0,
                    "top": 0,
                    "trailing": 0
                  },
                  "shape": {
                    "corners": {
                      "bottom_leading": 0,
                      "bottom_trailing": 0,
                      "top_leading": 0,
                      "top_trailing": 0
                    },
                    "type": "rectangle"
                  },
                  "size": {
                    "height": {
                      "type": "fit"
                    },
                    "width": {
                      "type": "fill"
                    }
                  },
                  "spacing": 0,
                  "type": "stack"
                },
                {
                  "components": [
                    {
                      "color": {
                        "light": {
                          "type": "hex",
                          "value": "#000000"
                        }
                      },
                      "font_size": 26,
                      "font_weight": "extra_bold",
                      "horizontal_alignment": "leading",
                      "id": "LmstcnaFVD",
                      "margin": {
                        "bottom": 0,
                        "leading": 0,
                        "top": 0,
                        "trailing": 0
                      },
                      "name": "",
                      "padding": {
                        "bottom": 0,
                        "leading": 0,
                        "top": 0,
                        "trailing": 0
                      },
                      "size": {
                        "height": {
                          "type": "fit"
                        },
                        "width": {
                          "type": "fill"
                        }
                      },
                      "text_lid": "FyNUTRxiCp",
                      "type": "text"
                    },
                    {
                      "color": {
                        "light": {
                          "type": "hex",
                          "value": "#555555ff"
                        }
                      },
                      "font_size": 16,
                      "font_weight": "medium",
                      "horizontal_alignment": "leading",
                      "id": "HUfc98iDG1",
                      "margin": {
                        "bottom": 0,
                        "leading": 0,
                        "top": 0,
                        "trailing": 0
                      },
                      "name": "",
                      "padding": {
                        "bottom": 0,
                        "leading": 0,
                        "top": 0,
                        "trailing": 0
                      },
                      "size": {
                        "height": {
                          "type": "fit"
                        },
                        "width": {
                          "type": "fill"
                        }
                      },
                      "text_lid": "kWOnHIvCdo",
                      "type": "text"
                    },
                    {
                      "components": [
                        {
                          "id": "RIgFQpgAtv",
                          "is_selected_by_default": false,
                          "name": "Package #1",
                          "package_id": "$rc_monthly",
                          "stack": {
                            "border": {
                              "color": {
                                "light": {
                                  "type": "hex",
                                  "value": "#cccccc"
                                }
                              },
                              "width": 1
                            },
                            "components": [
                              {
                                "base_url": "https://icons.pawwalls.com/icons",
                                "color": {
                                  "light": {
                                    "type": "hex",
                                    "value": "#ccccccff"
                                  }
                                },
                                "formats": {
                                  "heic": "circle.heic",
                                  "png": "circle.png",
                                  "svg": "circle.svg",
                                  "webp": "circle.webp"
                                },
                                "icon_name": "circle",
                                "id": "4DiMiz8wsL",
                                "margin": {
                                  "bottom": 0,
                                  "leading": 0,
                                  "top": 0,
                                  "trailing": 0
                                },
                                "name": "",
                                "overrides": [
                                  {
                                    "conditions": [
                                      {
                                        "type": "selected"
                                      }
                                    ],
                                    "properties": {
                                      "color": {
                                        "light": {
                                          "type": "hex",
                                          "value": "#b160deff"
                                        }
                                      },
                                      "formats": {
                                        "heic": "filled-circle-check.heic",
                                        "png": "filled-circle-check.png",
                                        "svg": "filled-circle-check.svg",
                                        "webp": "filled-circle-check.webp"
                                      },
                                      "icon_name": "filled-circle-check"
                                    }
                                  }
                                ],
                                "padding": {
                                  "bottom": 0,
                                  "leading": 0,
                                  "top": 0,
                                  "trailing": 0
                                },
                                "size": {
                                  "height": {
                                    "type": "fixed",
                                    "value": 24
                                  },
                                  "width": {
                                    "type": "fixed",
                                    "value": 24
                                  }
                                },
                                "type": "icon"
                              },
                              {
                                "components": [
                                  {
                                    "color": {
                                      "light": {
                                        "type": "hex",
                                        "value": "#000000"
                                      }
                                    },
                                    "font_size": 14,
                                    "font_weight": "bold",
                                    "horizontal_alignment": "leading",
                                    "id": "HXomvEok61",
                                    "margin": {
                                      "bottom": 0,
                                      "leading": 0,
                                      "top": 0,
                                      "trailing": 0
                                    },
                                    "name": "",
                                    "padding": {
                                      "bottom": 0,
                                      "leading": 0,
                                      "top": 0,
                                      "trailing": 0
                                    },
                                    "size": {
                                      "height": {
                                        "type": "fit"
                                      },
                                      "width": {
                                        "type": "fill"
                                      }
                                    },
                                    "text_lid": "P1z_6vh2dB",
                                    "type": "text"
                                  },
                                  {
                                    "color": {
                                      "light": {
                                        "type": "hex",
                                        "value": "#727272FF"
                                      }
                                    },
                                    "font_size": 13,
                                    "font_weight": "semibold",
                                    "horizontal_alignment": "leading",
                                    "id": "njKGuohI3U",
                                    "margin": {
                                      "bottom": 0,
                                      "leading": 0,
                                      "top": 0,
                                      "trailing": 0
                                    },
                                    "name": "",
                                    "padding": {
                                      "bottom": 0,
                                      "leading": 0,
                                      "top": 0,
                                      "trailing": 0
                                    },
                                    "size": {
                                      "height": {
                                        "type": "fit"
                                      },
                                      "width": {
                                        "type": "fill"
                                      }
                                    },
                                    "text_lid": "qovTSwipry",
                                    "type": "text"
                                  }
                                ],
                                "dimension": {
                                  "alignment": "leading",
                                  "distribution": "start",
                                  "type": "vertical"
                                },
                                "id": "iYnCnLu5hg",
                                "margin": {
                                  "bottom": 0,
                                  "leading": 0,
                                  "top": 0,
                                  "trailing": 0
                                },
                                "name": "",
                                "padding": {
                                  "bottom": 0,
                                  "leading": 0,
                                  "top": 0,
                                  "trailing": 0
                                },
                                "shape": {
                                  "corners": {
                                    "bottom_leading": 0,
                                    "bottom_trailing": 0,
                                    "top_leading": 0,
                                    "top_trailing": 0
                                  },
                                  "type": "rectangle"
                                },
                                "size": {
                                  "height": {
                                    "type": "fit"
                                  },
                                  "width": {
                                    "type": "fill"
                                  }
                                },
                                "spacing": 2,
                                "type": "stack"
                              }
                            ],
                            "dimension": {
                              "alignment": "center",
                              "distribution": "space_between",
                              "type": "horizontal"
                            },
                            "id": "mslHZ-ivsc",
                            "margin": {
                              "bottom": 4,
                              "leading": 0,
                              "top": 4,
                              "trailing": 0
                            },
                            "name": "",
                            "overrides": [
                              {
                                "conditions": [
                                  {
                                    "type": "selected"
                                  }
                                ],
                                "properties": {
                                  "border": {
                                    "color": {
                                      "light": {
                                        "type": "hex",
                                        "value": "#b160deff"
                                      }
                                    },
                                    "width": 1
                                  }
                                }
                              }
                            ],
                            "padding": {
                              "bottom": 16,
                              "leading": 8,
                              "top": 16,
                              "trailing": 8
                            },
                            "shape": {
                              "corners": {
                                "bottom_leading": 8,
                                "bottom_trailing": 8,
                                "top_leading": 8,
                                "top_trailing": 8
                              },
                              "type": "rectangle"
                            },
                            "size": {
                              "height": {
                                "type": "fit"
                              },
                              "width": {
                                "type": "fill"
                              }
                            },
                            "spacing": 6,
                            "type": "stack"
                          },
                          "type": "package"
                        },
                        {
                          "id": "eyIMS2cS9S",
                          "is_selected_by_default": true,
                          "name": "Package #2",
                          "package_id": "$rc_annual",
                          "stack": {
                            "badge": {
                              "alignment": "top_trailing",
                              "stack": {
                                "background": {
                                  "type": "color",
                                  "value": {
                                    "light": {
                                      "type": "hex",
                                      "value": "#f0dff9ff"
                                    }
                                  }
                                },
                                "background_color": {
                                  "light": {
                                    "type": "hex",
                                    "value": "#f0dff9ff"
                                  }
                                },
                                "border": {
                                  "color": {
                                    "dark": {
                                      "type": "hex",
                                      "value": "#ccccccff"
                                    },
                                    "light": {
                                      "type": "hex",
                                      "value": "#ccccccff"
                                    }
                                  },
                                  "width": 1
                                },
                                "components": [
                                  {
                                    "color": {
                                      "light": {
                                        "type": "hex",
                                        "value": "#000000ff"
                                      }
                                    },
                                    "font_size": 10,
                                    "font_weight": "bold",
                                    "horizontal_alignment": "center",
                                    "id": "U6lIMX-6Wk",
                                    "margin": {
                                      "bottom": 0,
                                      "leading": 0,
                                      "top": 0,
                                      "trailing": 0
                                    },
                                    "name": "",
                                    "padding": {
                                      "bottom": 0,
                                      "leading": 0,
                                      "top": 0,
                                      "trailing": 0
                                    },
                                    "size": {
                                      "height": {
                                        "type": "fit"
                                      },
                                      "width": {
                                        "type": "fit"
                                      }
                                    },
                                    "text_lid": "eyNwv3oRE2",
                                    "type": "text"
                                  }
                                ],
                                "dimension": {
                                  "alignment": "center",
                                  "distribution": "center",
                                  "type": "vertical"
                                },
                                "id": "KxLAqdB-Vo",
                                "margin": {
                                  "bottom": 4,
                                  "leading": 4,
                                  "top": 4,
                                  "trailing": 4
                                },
                                "name": "",
                                "padding": {
                                  "bottom": 4,
                                  "leading": 6,
                                  "top": 4,
                                  "trailing": 6
                                },
                                "shadow": {
                                  "color": {
                                    "dark": {
                                      "type": "hex",
                                      "value": "#ccccccff"
                                    },
                                    "light": {
                                      "type": "hex",
                                      "value": "#ccccccff"
                                    }
                                  },
                                  "radius": 2,
                                  "x": 0,
                                  "y": 0
                                },
                                "shape": {
                                  "corners": {
                                    "bottom_leading": 4,
                                    "bottom_trailing": 4,
                                    "top_leading": 4,
                                    "top_trailing": 4
                                  },
                                  "type": "rectangle"
                                },
                                "size": {
                                  "height": {
                                    "type": "fit"
                                  },
                                  "width": {
                                    "type": "fit"
                                  }
                                },
                                "spacing": 0,
                                "type": "stack"
                              },
                              "style": "nested"
                            },
                            "border": {
                              "color": {
                                "light": {
                                  "type": "hex",
                                  "value": "#cccccc"
                                }
                              },
                              "width": 1
                            },
                            "components": [
                              {
                                "base_url": "https://icons.pawwalls.com/icons",
                                "color": {
                                  "light": {
                                    "type": "hex",
                                    "value": "#ccccccff"
                                  }
                                },
                                "formats": {
                                  "heic": "circle.heic",
                                  "png": "circle.png",
                                  "svg": "circle.svg",
                                  "webp": "circle.webp"
                                },
                                "icon_name": "circle",
                                "id": "mK-pHQSSnT",
                                "margin": {
                                  "bottom": 0,
                                  "leading": 0,
                                  "top": 0,
                                  "trailing": 0
                                },
                                "name": "",
                                "overrides": [
                                  {
                                    "conditions": [
                                      {
                                        "type": "selected"
                                      }
                                    ],
                                    "properties": {
                                      "color": {
                                        "light": {
                                          "type": "hex",
                                          "value": "#b160deff"
                                        }
                                      },
                                      "formats": {
                                        "heic": "filled-circle-check.heic",
                                        "png": "filled-circle-check.png",
                                        "svg": "filled-circle-check.svg",
                                        "webp": "filled-circle-check.webp"
                                      },
                                      "icon_name": "filled-circle-check"
                                    }
                                  }
                                ],
                                "padding": {
                                  "bottom": 0,
                                  "leading": 0,
                                  "top": 0,
                                  "trailing": 0
                                },
                                "size": {
                                  "height": {
                                    "type": "fixed",
                                    "value": 24
                                  },
                                  "width": {
                                    "type": "fixed",
                                    "value": 24
                                  }
                                },
                                "type": "icon"
                              },
                              {
                                "components": [
                                  {
                                    "background_color": {
                                      "light": {
                                        "type": "hex",
                                        "value": "#ffffffff"
                                      }
                                    },
                                    "color": {
                                      "light": {
                                        "type": "hex",
                                        "value": "#000000"
                                      }
                                    },
                                    "font_size": 14,
                                    "font_weight": "bold",
                                    "horizontal_alignment": "leading",
                                    "id": "vd85YJTYQx",
                                    "margin": {
                                      "bottom": 0,
                                      "leading": 0,
                                      "top": 0,
                                      "trailing": 0
                                    },
                                    "name": "",
                                    "padding": {
                                      "bottom": 0,
                                      "leading": 0,
                                      "top": 0,
                                      "trailing": 0
                                    },
                                    "size": {
                                      "height": {
                                        "type": "fit"
                                      },
                                      "width": {
                                        "type": "fill"
                                      }
                                    },
                                    "text_lid": "Uy6I2dFmQb",
                                    "type": "text"
                                  },
                                  {
                                    "color": {
                                      "light": {
                                        "type": "hex",
                                        "value": "#727272FF"
                                      }
                                    },
                                    "font_size": 13,
                                    "font_weight": "semibold",
                                    "horizontal_alignment": "leading",
                                    "id": "bwWAo9iaJH",
                                    "margin": {
                                      "bottom": 0,
                                      "leading": 0,
                                      "top": 0,
                                      "trailing": 0
                                    },
                                    "name": "",
                                    "padding": {
                                      "bottom": 0,
                                      "leading": 0,
                                      "top": 0,
                                      "trailing": 0
                                    },
                                    "size": {
                                      "height": {
                                        "type": "fit"
                                      },
                                      "width": {
                                        "type": "fill"
                                      }
                                    },
                                    "text_lid": "qt7jepvJD4",
                                    "type": "text"
                                  }
                                ],
                                "dimension": {
                                  "alignment": "leading",
                                  "distribution": "start",
                                  "type": "vertical"
                                },
                                "id": "kdNEth435S",
                                "margin": {
                                  "bottom": 0,
                                  "leading": 0,
                                  "top": 0,
                                  "trailing": 0
                                },
                                "name": "",
                                "padding": {
                                  "bottom": 0,
                                  "leading": 0,
                                  "top": 0,
                                  "trailing": 0
                                },
                                "shape": {
                                  "corners": {
                                    "bottom_leading": 0,
                                    "bottom_trailing": 0,
                                    "top_leading": 0,
                                    "top_trailing": 0
                                  },
                                  "type": "rectangle"
                                },
                                "size": {
                                  "height": {
                                    "type": "fit"
                                  },
                                  "width": {
                                    "type": "fill"
                                  }
                                },
                                "spacing": 2,
                                "type": "stack"
                              }
                            ],
                            "dimension": {
                              "alignment": "center",
                              "distribution": "space_between",
                              "type": "horizontal"
                            },
                            "id": "Tv_hWt_NQw",
                            "margin": {
                              "bottom": 4,
                              "leading": 0,
                              "top": 4,
                              "trailing": 0
                            },
                            "name": "",
                            "overrides": [
                              {
                                "conditions": [
                                  {
                                    "type": "selected"
                                  }
                                ],
                                "properties": {
                                  "border": {
                                    "color": {
                                      "light": {
                                        "type": "hex",
                                        "value": "#b160deff"
                                      }
                                    },
                                    "width": 1
                                  }
                                }
                              }
                            ],
                            "padding": {
                              "bottom": 16,
                              "leading": 8,
                              "top": 16,
                              "trailing": 8
                            },
                            "shape": {
                              "corners": {
                                "bottom_leading": 8,
                                "bottom_trailing": 8,
                                "top_leading": 8,
                                "top_trailing": 8
                              },
                              "type": "rectangle"
                            },
                            "size": {
                              "height": {
                                "type": "fit"
                              },
                              "width": {
                                "type": "fill"
                              }
                            },
                            "spacing": 6,
                            "type": "stack"
                          },
                          "type": "package"
                        }
                      ],
                      "dimension": {
                        "alignment": "top",
                        "distribution": "space_between",
                        "type": "horizontal"
                      },
                      "id": "00dWKbUxsa",
                      "margin": {
                        "bottom": 12,
                        "leading": 0,
                        "top": 40,
                        "trailing": 0
                      },
                      "name": "Package list",
                      "padding": {
                        "bottom": 0,
                        "leading": 0,
                        "top": 0,
                        "trailing": 0
                      },
                      "shape": {
                        "corners": {
                          "bottom_leading": 0,
                          "bottom_trailing": 0,
                          "top_leading": 0,
                          "top_trailing": 0
                        },
                        "type": "rectangle"
                      },
                      "size": {
                        "height": {
                          "type": "fit"
                        },
                        "width": {
                          "type": "fill"
                        }
                      },
                      "spacing": 8,
                      "type": "stack"
                    }
                  ],
                  "dimension": {
                    "alignment": "leading",
                    "distribution": "start",
                    "type": "vertical"
                  },
                  "id": "O3mpaN_fgX",
                  "margin": {
                    "bottom": 8,
                    "leading": 20,
                    "top": 32,
                    "trailing": 20
                  },
                  "name": "Main content",
                  "padding": {
                    "bottom": 0,
                    "leading": 0,
                    "top": 0,
                    "trailing": 0
                  },
                  "shape": {
                    "corners": {
                      "bottom_leading": 0,
                      "bottom_trailing": 0,
                      "top_leading": 0,
                      "top_trailing": 0
                    },
                    "type": "rectangle"
                  },
                  "size": {
                    "height": {
                      "type": "fit"
                    },
                    "width": {
                      "type": "fill"
                    }
                  },
                  "spacing": 4,
                  "type": "stack"
                },
                {
                  "id": "W1y3Eqnqqy",
                  "name": "",
                  "stack": {
                    "background": {
                      "type": "color",
                      "value": {
                        "light": {
                          "degrees": 135,
                          "points": [
                            {
                              "color": "#5119dcff",
                              "percent": 0
                            },
                            {
                              "color": "#f0bca2ff",
                              "percent": 100
                            }
                          ],
                          "type": "linear"
                        }
                      }
                    },
                    "components": [
                      {
                        "color": {
                          "light": {
                            "type": "hex",
                            "value": "#ffffff"
                          }
                        },
                        "font_size": 16,
                        "font_weight": "semibold",
                        "horizontal_alignment": "center",
                        "id": "BQuutDOFV5",
                        "margin": {
                          "bottom": 0,
                          "leading": 0,
                          "top": 0,
                          "trailing": 0
                        },
                        "name": "",
                        "padding": {
                          "bottom": 0,
                          "leading": 0,
                          "top": 0,
                          "trailing": 0
                        },
                        "size": {
                          "height": {
                            "type": "fit"
                          },
                          "width": {
                            "type": "fill"
                          }
                        },
                        "text_lid": "syle56RkVU",
                        "type": "text"
                      }
                    ],
                    "dimension": {
                      "alignment": "leading",
                      "distribution": "start",
                      "type": "vertical"
                    },
                    "id": "KawOIza7qP",
                    "margin": {
                      "bottom": 0,
                      "leading": 20,
                      "top": 0,
                      "trailing": 20
                    },
                    "name": "",
                    "padding": {
                      "bottom": 12,
                      "leading": 8,
                      "top": 12,
                      "trailing": 8
                    },
                    "shape": {
                      "corners": {
                        "bottom_leading": 8,
                        "bottom_trailing": 8,
                        "top_leading": 8,
                        "top_trailing": 8
                      },
                      "type": "rectangle"
                    },
                    "size": {
                      "height": {
                        "type": "fit"
                      },
                      "width": {
                        "type": "fill"
                      }
                    },
                    "spacing": 0,
                    "type": "stack"
                  },
                  "type": "purchase_button"
                },
                {
                  "components": [
                    {
                      "color": {
                        "light": {
                          "type": "hex",
                          "value": "#727272ff"
                        }
                      },
                      "font_size": 13,
                      "font_weight": "semibold",
                      "horizontal_alignment": "leading",
                      "id": "56ruxqv1jH",
                      "margin": {
                        "bottom": 0,
                        "leading": 0,
                        "top": 0,
                        "trailing": 0
                      },
                      "name": "",
                      "padding": {
                        "bottom": 0,
                        "leading": 0,
                        "top": 0,
                        "trailing": 0
                      },
                      "size": {
                        "height": {
                          "type": "fit"
                        },
                        "width": {
                          "type": "fit"
                        }
                      },
                      "text_lid": "Bm7Ee_2XMH",
                      "type": "text"
                    },
                    {
                      "action": {
                        "type": "restore_purchases"
                      },
                      "id": "6rdSAjxs0_",
                      "name": "",
                      "stack": {
                        "components": [
                          {
                            "color": {
                              "light": {
                                "type": "hex",
                                "value": "#5119dcff"
                              }
                            },
                            "font_size": 13,
                            "font_weight": "medium",
                            "horizontal_alignment": "leading",
                            "id": "b_AoJXqufl",
                            "margin": {
                              "bottom": 0,
                              "leading": 0,
                              "top": 0,
                              "trailing": 0
                            },
                            "name": "",
                            "padding": {
                              "bottom": 0,
                              "leading": 0,
                              "top": 0,
                              "trailing": 0
                            },
                            "size": {
                              "height": {
                                "type": "fit"
                              },
                              "width": {
                                "type": "fit"
                              }
                            },
                            "text_lid": "SYFxRac3Hg",
                            "type": "text"
                          }
                        ],
                        "dimension": {
                          "alignment": "leading",
                          "distribution": "start",
                          "type": "vertical"
                        },
                        "id": "-GglMxCfF4",
                        "margin": {
                          "bottom": 0,
                          "leading": 0,
                          "top": 0,
                          "trailing": 0
                        },
                        "name": "",
                        "padding": {
                          "bottom": 0,
                          "leading": 0,
                          "top": 0,
                          "trailing": 0
                        },
                        "shape": {
                          "corners": {
                            "bottom_leading": 0,
                            "bottom_trailing": 0,
                            "top_leading": 0,
                            "top_trailing": 0
                          },
                          "type": "rectangle"
                        },
                        "size": {
                          "height": {
                            "type": "fit"
                          },
                          "width": {
                            "type": "fit"
                          }
                        },
                        "spacing": 0,
                        "type": "stack"
                      },
                      "type": "button"
                    }
                  ],
                  "dimension": {
                    "alignment": "top",
                    "distribution": "space_evenly",
                    "type": "horizontal"
                  },
                  "id": "YZLvA_5r4v",
                  "margin": {
                    "bottom": 4,
                    "leading": 0,
                    "top": 4,
                    "trailing": 0
                  },
                  "name": "Additional text",
                  "padding": {
                    "bottom": 8,
                    "leading": 0,
                    "top": 8,
                    "trailing": 0
                  },
                  "shape": {
                    "corners": {
                      "bottom_leading": 0,
                      "bottom_trailing": 0,
                      "top_leading": 0,
                      "top_trailing": 0
                    },
                    "type": "rectangle"
                  },
                  "size": {
                    "height": {
                      "type": "fit"
                    },
                    "width": {
                      "type": "fill"
                    }
                  },
                  "spacing": 4,
                  "type": "stack"
                }
              ],
              "dimension": {
                "alignment": "leading",
                "distribution": "start",
                "type": "vertical"
              },
              "id": "ox9EmTiAJf",
              "margin": {
                "bottom": 0,
                "leading": 0,
                "top": 0,
                "trailing": 0
              },
              "name": "Content",
              "padding": {
                "bottom": 0,
                "leading": 0,
                "top": 0,
                "trailing": 0
              },
              "shape": {
                "corners": {
                  "bottom_leading": 0,
                  "bottom_trailing": 0,
                  "top_leading": 0,
                  "top_trailing": 0
                },
                "type": "rectangle"
              },
              "size": {
                "height": {
                  "type": "fit"
                },
                "width": {
                  "type": "fill"
                }
              },
              "spacing": 0,
              "type": "stack"
            }
          }
        },
        "components_localizations": {
          "en_US": {
            "Bm7Ee_2XMH": "Cancel anytime.",
            "FyNUTRxiCp": "Experience Pro today!",
            "P1z_6vh2dB": "Monthly",
            "SYFxRac3Hg": "Restore purchases.",
            "Uy6I2dFmQb": "Yearly",
            "eyNwv3oRE2": "{{ product.relative_discount }} OFF",
            "kWOnHIvCdo": "Check out the power of all we offer.",
            "qovTSwipry": "{{ product.price_per_period_abbreviated }}",
            "qt7jepvJD4": "{{ product.price_per_period_abbreviated }}",
            "syle56RkVU": "Continue"
          }
        },
        "default_locale": "en_US",
        "revision": 66,
        "template_name": "components",
        "zero_decimal_place_countries": {
          "apple": [
            "TWN",
            "KAZ",
            "MEX",
            "PHL",
            "THA"
          ],
          "google": [
            "TW",
            "KZ",
            "MX",
            "PH",
            "TH"
          ]
        }
      }
    }
"""
