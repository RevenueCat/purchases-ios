//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
// swiftlint:disable line_length

#if DEBUG && !os(tvOS)

import Foundation
@_spi(Internal) import RevenueCat
import StoreKit
import SwiftUI

private enum MinMaxPaywallPreview {

    private static let offeringIdentifier = "min-max-preview"
    // This fixture is intentionally taller than a device. Emerge captures fixed-layout previews at their declared
    // size, which keeps the full paywall at its natural scale instead of compressing it into a phone-height proposal.
    static let previewHeight: CGFloat = 6_600
    private static let resourceName = "min-max-paywall-preview"

    struct Fixture {
        let offering: Offering
        let paywallComponents: Offering.PaywallComponents
    }

    enum LoadingError: LocalizedError {
        case missingResource

        var errorDescription: String? {
            switch self {
            case .missingResource:
                return "Missing \(MinMaxPaywallPreview.resourceName).json from the preview host bundle."
            }
        }
    }

    static func load() throws -> Fixture {

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        let jsonData = json.data(using: String.Encoding.utf8) ?? .init()
        let data = try decoder.decode(PaywallComponentsData.self, from: jsonData)
        let paywallComponents = Offering.PaywallComponents(uiConfig: PreviewUIConfig.make(), data: data)
        let packages = self.packages
        let offering = Offering(
            identifier: self.offeringIdentifier,
            serverDescription: "Min/max sizing preview",
            paywallComponents: paywallComponents,
            availablePackages: packages,
            webCheckoutUrl: nil
        )

        return Fixture(offering: offering, paywallComponents: paywallComponents)
    }

    private static var packages: [Package] {
        return [
            self.package(
                identifier: "$rc_weekly",
                type: .weekly,
                price: 4.99,
                period: .week,
                title: "Weekly"
            ),
            self.package(
                identifier: "$rc_monthly",
                type: .monthly,
                price: 12.99,
                period: .month,
                title: "Monthly"
            ),
            self.package(
                identifier: "$rc_annual",
                type: .annual,
                price: 69.99,
                period: .year,
                title: "Annual"
            )
        ]
    }

    private static func package(
        identifier: String,
        type: PackageType,
        price: NSDecimalNumber,
        period: SKProduct.PeriodUnit,
        title: String
    ) -> Package {
        return Package(
            identifier: identifier,
            packageType: type,
            storeProduct: .init(sk1Product: PreviewMock.Product(
                price: price,
                unit: period,
                localizedTitle: title
            )),
            offeringIdentifier: self.offeringIdentifier,
            webCheckoutUrl: nil
        )
    }

}

@MainActor
@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
struct MinMaxPaywallPreview_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            switch Result(catching: MinMaxPaywallPreview.load) {
            case .success(let fixture):
                PaywallsV2View(
                    paywallComponents: fixture.paywallComponents,
                    offering: fixture.offering,
                    purchaseHandler: PurchaseHandler.default(),
                    introEligibilityChecker: .default(),
                    showZeroDecimalPlacePrices: true,
                    onDismiss: { },
                    failedToLoadFont: { _ in },
                    colorScheme: .light
                )
                .previewRequiredPaywallsV2Properties()
                .emergeExpansion(true)

            case .failure(let error):
                Text("Unable to load min/max paywall preview:\n\(error.localizedDescription)")
                    .padding()
            }
        }
        .previewLayout(.fixed(width: 402, height: MinMaxPaywallPreview.previewHeight))
        .previewDisplayName("Min/max sizing – full paywall")
    }

}

let json = #"""
{
  "asset_base_url": "https://assets.pawwalls.com",
  "automatically_scale_font_size": true,
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
      "header": null,
      "stack": {
        "type": "stack",
        "id": "stk_342",
        "name": "Min/Max test sheet",
        "components": [
          {
            "type": "text",
            "id": "txt_335",
            "name": "Min / Max size constraints test ",
            "text_lid": "txt_335",
            "color": {
              "light": {
                "type": "hex",
                "value": "#111111ff"
              }
            },
            "font_size": 18,
            "font_weight": "bold",
            "horizontal_alignment": "leading",
            "size": {
              "width": {
                "type": "fit"
              },
              "height": {
                "type": "fit"
              }
            },
            "padding": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "margin": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            }
          },
          {
            "type": "text",
            "id": "txt_336",
            "name": "Each section states the expected",
            "text_lid": "txt_336",
            "color": {
              "light": {
                "type": "hex",
                "value": "#6e6e73ff"
              }
            },
            "font_size": 11,
            "font_weight": "regular",
            "horizontal_alignment": "leading",
            "size": {
              "width": {
                "type": "fit"
              },
              "height": {
                "type": "fit"
              }
            },
            "padding": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "margin": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            }
          },
          {
            "type": "stack",
            "id": "stk_340",
            "name": "root width ruler",
            "components": [
              {
                "type": "text",
                "id": "txt_337",
                "name": "root width",
                "text_lid": "txt_337",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#ffffffff"
                  }
                },
                "font_size": 9,
                "font_weight": "regular",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "stack",
                "id": "stk_338",
                "name": "#ffffffff",
                "components": [],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fixed",
                    "value": 4
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 8,
                    "top_trailing": 8,
                    "bottom_leading": 8,
                    "bottom_trailing": 8
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#ffffffff"
                    }
                  }
                },
                "border": null,
                "shadow": null
              },
              {
                "type": "text",
                "id": "txt_339",
                "name": "root width",
                "text_lid": "txt_339",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#ffffffff"
                  }
                },
                "font_size": 9,
                "font_weight": "regular",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              }
            ],
            "dimension": {
              "type": "horizontal",
              "alignment": "center",
              "distribution": "start"
            },
            "size": {
              "width": {
                "type": "fill"
              },
              "height": {
                "type": "fit"
              }
            },
            "spacing": 8,
            "padding": {
              "leading": 4,
              "trailing": 4,
              "top": 4,
              "bottom": 4
            },
            "margin": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "shape": {
              "type": "rectangle",
              "corners": {
                "top_leading": 0,
                "top_trailing": 0,
                "bottom_leading": 0,
                "bottom_trailing": 0
              }
            },
            "background": {
              "type": "color",
              "value": {
                "light": {
                  "type": "hex",
                  "value": "#2c3592ff"
                }
              }
            },
            "border": null,
            "shadow": null
          },
          {
            "type": "stack",
            "id": "stk_008",
            "name": "1. Capped Fill sibling redistributes leftover",
            "components": [
              {
                "type": "text",
                "id": "txt_005",
                "name": "1. Capped Fill sibling redistrib",
                "text_lid": "txt_005",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#111111ff"
                  }
                },
                "font_size": 13,
                "font_weight": "bold",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "text",
                "id": "txt_006",
                "name": "Row: Fill(max 60) | Fill | Fill(",
                "text_lid": "txt_006",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#6e6e73ff"
                  }
                },
                "font_size": 11,
                "font_weight": "regular",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "stack",
                "id": "stk_007",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_004",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_001",
                        "name": "#576cdbff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill",
                            "max": 60
                          },
                          "height": {
                            "type": "fixed",
                            "value": 48
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#576cdbff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_002",
                        "name": "#f4a259ff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill"
                          },
                          "height": {
                            "type": "fixed",
                            "value": 48
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#f4a259ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_003",
                        "name": "#8fc7a2ff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill",
                            "min": 140
                          },
                          "height": {
                            "type": "fixed",
                            "value": 48
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#8fc7a2ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "horizontal",
                      "alignment": "center",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              }
            ],
            "dimension": {
              "type": "vertical",
              "alignment": "leading",
              "distribution": "start"
            },
            "size": {
              "width": {
                "type": "fill"
              },
              "height": {
                "type": "fit"
              }
            },
            "spacing": 6,
            "padding": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "margin": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "shape": {
              "type": "rectangle",
              "corners": {
                "top_leading": 8,
                "top_trailing": 8,
                "bottom_leading": 8,
                "bottom_trailing": 8
              }
            },
            "background": null,
            "border": null,
            "shadow": null
          },
          {
            "type": "stack",
            "id": "stk_021",
            "name": "2. Fit(min/max) child next to a Fill sibling",
            "components": [
              {
                "type": "text",
                "id": "txt_017",
                "name": "2. Fit(min/max) child next to a ",
                "text_lid": "txt_017",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#111111ff"
                  }
                },
                "font_size": 13,
                "font_weight": "bold",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "text",
                "id": "txt_018",
                "name": "Blue is Fit(min 100, max 160) ar",
                "text_lid": "txt_018",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#6e6e73ff"
                  }
                },
                "font_size": 11,
                "font_weight": "regular",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "stack",
                "id": "stk_019",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_012",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_010",
                        "name": "",
                        "components": [
                          {
                            "type": "text",
                            "id": "txt_009",
                            "name": "hi",
                            "text_lid": "txt_009",
                            "color": {
                              "light": {
                                "type": "hex",
                                "value": "#ffffffff"
                              }
                            },
                            "font_size": 11,
                            "font_weight": "regular",
                            "horizontal_alignment": "leading",
                            "size": {
                              "width": {
                                "type": "fit"
                              },
                              "height": {
                                "type": "fit"
                              }
                            },
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            }
                          }
                        ],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "center"
                        },
                        "size": {
                          "width": {
                            "type": "fit",
                            "min": 100,
                            "max": 160
                          },
                          "height": {
                            "type": "fit",
                            "min": 48
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#576cdbff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_011",
                        "name": "#f4a259ff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill"
                          },
                          "height": {
                            "type": "fixed",
                            "value": 48
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#f4a259ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "horizontal",
                      "alignment": "center",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              },
              {
                "type": "stack",
                "id": "stk_020",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_016",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_014",
                        "name": "",
                        "components": [
                          {
                            "type": "text",
                            "id": "txt_013",
                            "name": "this text is long enough to hit ",
                            "text_lid": "txt_013",
                            "color": {
                              "light": {
                                "type": "hex",
                                "value": "#ffffffff"
                              }
                            },
                            "font_size": 11,
                            "font_weight": "regular",
                            "horizontal_alignment": "leading",
                            "size": {
                              "width": {
                                "type": "fit"
                              },
                              "height": {
                                "type": "fit"
                              }
                            },
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            }
                          }
                        ],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "center"
                        },
                        "size": {
                          "width": {
                            "type": "fit",
                            "min": 100,
                            "max": 160
                          },
                          "height": {
                            "type": "fit",
                            "min": 48
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 4,
                          "trailing": 4,
                          "top": 4,
                          "bottom": 4
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#576cdbff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_015",
                        "name": "#f4a259ff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill"
                          },
                          "height": {
                            "type": "fixed",
                            "value": 48
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#f4a259ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "horizontal",
                      "alignment": "center",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              }
            ],
            "dimension": {
              "type": "vertical",
              "alignment": "leading",
              "distribution": "start"
            },
            "size": {
              "width": {
                "type": "fill"
              },
              "height": {
                "type": "fit"
              }
            },
            "spacing": 6,
            "padding": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "margin": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "shape": {
              "type": "rectangle",
              "corners": {
                "top_leading": 8,
                "top_trailing": 8,
                "bottom_leading": 8,
                "bottom_trailing": 8
              }
            },
            "background": null,
            "border": null,
            "shadow": null
          },
          {
            "type": "stack",
            "id": "stk_042",
            "name": "3. Fit(min) stack hugs its minimum with SPACE_* distributions",
            "components": [
              {
                "type": "text",
                "id": "txt_037",
                "name": "3. Fit(min) stack hugs its minim",
                "text_lid": "txt_037",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#111111ff"
                  }
                },
                "font_size": 13,
                "font_weight": "bold",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "text",
                "id": "txt_038",
                "name": "Purple row is Fit(min 240) with ",
                "text_lid": "txt_038",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#6e6e73ff"
                  }
                },
                "font_size": 11,
                "font_weight": "regular",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "stack",
                "id": "stk_039",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_026",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_025",
                        "name": "",
                        "components": [
                          {
                            "type": "stack",
                            "id": "stk_022",
                            "name": "#f8dc78ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 32
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#f8dc78ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          },
                          {
                            "type": "stack",
                            "id": "stk_023",
                            "name": "#f8dc78ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 32
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#f8dc78ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          },
                          {
                            "type": "stack",
                            "id": "stk_024",
                            "name": "#f8dc78ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 32
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#f8dc78ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          }
                        ],
                        "dimension": {
                          "type": "horizontal",
                          "alignment": "center",
                          "distribution": "space_between"
                        },
                        "size": {
                          "width": {
                            "type": "fit",
                            "min": 240
                          },
                          "height": {
                            "type": "fit"
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 4,
                          "trailing": 4,
                          "top": 4,
                          "bottom": 4
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#9b8fd6ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "vertical",
                      "alignment": "center",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              },
              {
                "type": "stack",
                "id": "stk_040",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_031",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_030",
                        "name": "",
                        "components": [
                          {
                            "type": "stack",
                            "id": "stk_027",
                            "name": "#f8dc78ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 32
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#f8dc78ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          },
                          {
                            "type": "stack",
                            "id": "stk_028",
                            "name": "#f8dc78ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 32
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#f8dc78ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          },
                          {
                            "type": "stack",
                            "id": "stk_029",
                            "name": "#f8dc78ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 32
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#f8dc78ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          }
                        ],
                        "dimension": {
                          "type": "horizontal",
                          "alignment": "center",
                          "distribution": "space_around"
                        },
                        "size": {
                          "width": {
                            "type": "fit",
                            "min": 240
                          },
                          "height": {
                            "type": "fit"
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 4,
                          "trailing": 4,
                          "top": 4,
                          "bottom": 4
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#9b8fd6ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "vertical",
                      "alignment": "center",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              },
              {
                "type": "stack",
                "id": "stk_041",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_036",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_035",
                        "name": "",
                        "components": [
                          {
                            "type": "stack",
                            "id": "stk_032",
                            "name": "#f8dc78ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 32
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#f8dc78ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          },
                          {
                            "type": "stack",
                            "id": "stk_033",
                            "name": "#f8dc78ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 32
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#f8dc78ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          },
                          {
                            "type": "stack",
                            "id": "stk_034",
                            "name": "#f8dc78ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 32
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#f8dc78ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          }
                        ],
                        "dimension": {
                          "type": "horizontal",
                          "alignment": "center",
                          "distribution": "space_evenly"
                        },
                        "size": {
                          "width": {
                            "type": "fit",
                            "min": 240
                          },
                          "height": {
                            "type": "fit"
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 4,
                          "trailing": 4,
                          "top": 4,
                          "bottom": 4
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#9b8fd6ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "vertical",
                      "alignment": "center",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              }
            ],
            "dimension": {
              "type": "vertical",
              "alignment": "leading",
              "distribution": "start"
            },
            "size": {
              "width": {
                "type": "fill"
              },
              "height": {
                "type": "fit"
              }
            },
            "spacing": 6,
            "padding": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "margin": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "shape": {
              "type": "rectangle",
              "corners": {
                "top_leading": 8,
                "top_trailing": 8,
                "bottom_leading": 8,
                "bottom_trailing": 8
              }
            },
            "background": null,
            "border": null,
            "shadow": null
          },
          {
            "type": "stack",
            "id": "stk_063",
            "name": "4. Fit(max) smaller than content: overflow arrangement",
            "components": [
              {
                "type": "text",
                "id": "txt_058",
                "name": "4. Fit(max) smaller than content",
                "text_lid": "txt_058",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#111111ff"
                  }
                },
                "font_size": 13,
                "font_weight": "bold",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "text",
                "id": "txt_059",
                "name": "Purple row is Fit(max 160) holdi",
                "text_lid": "txt_059",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#6e6e73ff"
                  }
                },
                "font_size": 11,
                "font_weight": "regular",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "stack",
                "id": "stk_060",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_047",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_046",
                        "name": "",
                        "components": [
                          {
                            "type": "stack",
                            "id": "stk_043",
                            "name": "#f8dc78ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 64
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#f8dc78ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          },
                          {
                            "type": "stack",
                            "id": "stk_044",
                            "name": "#8fc7a2ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 64
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#8fc7a2ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          },
                          {
                            "type": "stack",
                            "id": "stk_045",
                            "name": "#d94f5cff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 64
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#d94f5cff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          }
                        ],
                        "dimension": {
                          "type": "horizontal",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fit",
                            "max": 160
                          },
                          "height": {
                            "type": "fit"
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 4,
                          "trailing": 4,
                          "top": 4,
                          "bottom": 4
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#9b8fd6ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "vertical",
                      "alignment": "center",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              },
              {
                "type": "stack",
                "id": "stk_061",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_052",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_051",
                        "name": "",
                        "components": [
                          {
                            "type": "stack",
                            "id": "stk_048",
                            "name": "#f8dc78ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 64
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#f8dc78ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          },
                          {
                            "type": "stack",
                            "id": "stk_049",
                            "name": "#8fc7a2ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 64
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#8fc7a2ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          },
                          {
                            "type": "stack",
                            "id": "stk_050",
                            "name": "#d94f5cff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 64
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#d94f5cff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          }
                        ],
                        "dimension": {
                          "type": "horizontal",
                          "alignment": "center",
                          "distribution": "center"
                        },
                        "size": {
                          "width": {
                            "type": "fit",
                            "max": 160
                          },
                          "height": {
                            "type": "fit"
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 4,
                          "trailing": 4,
                          "top": 4,
                          "bottom": 4
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#9b8fd6ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "vertical",
                      "alignment": "center",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              },
              {
                "type": "stack",
                "id": "stk_062",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_057",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_056",
                        "name": "",
                        "components": [
                          {
                            "type": "stack",
                            "id": "stk_053",
                            "name": "#f8dc78ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 64
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#f8dc78ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          },
                          {
                            "type": "stack",
                            "id": "stk_054",
                            "name": "#8fc7a2ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 64
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#8fc7a2ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          },
                          {
                            "type": "stack",
                            "id": "stk_055",
                            "name": "#d94f5cff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 64
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#d94f5cff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          }
                        ],
                        "dimension": {
                          "type": "horizontal",
                          "alignment": "center",
                          "distribution": "end"
                        },
                        "size": {
                          "width": {
                            "type": "fit",
                            "max": 160
                          },
                          "height": {
                            "type": "fit"
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 4,
                          "trailing": 4,
                          "top": 4,
                          "bottom": 4
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#9b8fd6ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "vertical",
                      "alignment": "center",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              }
            ],
            "dimension": {
              "type": "vertical",
              "alignment": "leading",
              "distribution": "start"
            },
            "size": {
              "width": {
                "type": "fill"
              },
              "height": {
                "type": "fit"
              }
            },
            "spacing": 6,
            "padding": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "margin": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "shape": {
              "type": "rectangle",
              "corners": {
                "top_leading": 8,
                "top_trailing": 8,
                "bottom_leading": 8,
                "bottom_trailing": 8
              }
            },
            "background": null,
            "border": null,
            "shadow": null
          },
          {
            "type": "stack",
            "id": "stk_071",
            "name": "5. Vertical: capped and floored Fill heights",
            "components": [
              {
                "type": "text",
                "id": "txt_068",
                "name": "5. Vertical: capped and floored ",
                "text_lid": "txt_068",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#111111ff"
                  }
                },
                "font_size": 13,
                "font_weight": "bold",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "text",
                "id": "txt_069",
                "name": "Column is Fixed 200 tall: Fill(m",
                "text_lid": "txt_069",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#6e6e73ff"
                  }
                },
                "font_size": 11,
                "font_weight": "regular",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "stack",
                "id": "stk_070",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_067",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_064",
                        "name": "#576cdbff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill"
                          },
                          "height": {
                            "type": "fill",
                            "max": 40
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#576cdbff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_065",
                        "name": "#f4a259ff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill"
                          },
                          "height": {
                            "type": "fill"
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#f4a259ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_066",
                        "name": "#8fc7a2ff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill"
                          },
                          "height": {
                            "type": "fill",
                            "min": 90
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#8fc7a2ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "vertical",
                      "alignment": "center",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fixed",
                        "value": 200
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              }
            ],
            "dimension": {
              "type": "vertical",
              "alignment": "leading",
              "distribution": "start"
            },
            "size": {
              "width": {
                "type": "fill"
              },
              "height": {
                "type": "fit"
              }
            },
            "spacing": 6,
            "padding": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "margin": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "shape": {
              "type": "rectangle",
              "corners": {
                "top_leading": 8,
                "top_trailing": 8,
                "bottom_leading": 8,
                "bottom_trailing": 8
              }
            },
            "background": null,
            "border": null,
            "shadow": null
          },
          {
            "type": "stack",
            "id": "stk_086",
            "name": "6. Cross-axis Fill under the root scroll (the red-block bug)",
            "components": [
              {
                "type": "text",
                "id": "txt_082",
                "name": "6. Cross-axis Fill under the roo",
                "text_lid": "txt_082",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#111111ff"
                  }
                },
                "font_size": 13,
                "font_weight": "bold",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "text",
                "id": "txt_083",
                "name": "Fit-height row inside the scroll",
                "text_lid": "txt_083",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#6e6e73ff"
                  }
                },
                "font_size": 11,
                "font_weight": "regular",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "stack",
                "id": "stk_084",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_075",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_072",
                        "name": "#1c1c1eff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fixed",
                            "value": 48
                          },
                          "height": {
                            "type": "fixed",
                            "value": 60
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#1c1c1eff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_073",
                        "name": "#d94f5cff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill",
                            "max": 40
                          },
                          "height": {
                            "type": "fill",
                            "max": 120
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#d94f5cff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_074",
                        "name": "#576cdbff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill"
                          },
                          "height": {
                            "type": "fill"
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#576cdbff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "horizontal",
                      "alignment": "center",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              },
              {
                "type": "stack",
                "id": "stk_085",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_081",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_076",
                        "name": "#1c1c1eff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fit",
                            "min": 64,
                            "max": 96
                          },
                          "height": {
                            "type": "fit",
                            "min": 120,
                            "max": 140
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#1c1c1eff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_079",
                        "name": "",
                        "components": [
                          {
                            "type": "stack",
                            "id": "stk_077",
                            "name": "#8fc7a2ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fill"
                              },
                              "height": {
                                "type": "fill"
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#8fc7a2ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          },
                          {
                            "type": "stack",
                            "id": "stk_078",
                            "name": "#e6e6e6ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fill",
                                "min": 120,
                                "max": 240
                              },
                              "height": {
                                "type": "fill",
                                "min": 48,
                                "max": 64
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#e6e6e6ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          }
                        ],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill",
                            "min": 120,
                            "max": 240
                          },
                          "height": {
                            "type": "fit",
                            "min": 120,
                            "max": 160
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": null,
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_080",
                        "name": "#d94f5cff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill",
                            "max": 40
                          },
                          "height": {
                            "type": "fill",
                            "max": 120
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#d94f5cff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "horizontal",
                      "alignment": "center",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              }
            ],
            "dimension": {
              "type": "vertical",
              "alignment": "leading",
              "distribution": "start"
            },
            "size": {
              "width": {
                "type": "fill"
              },
              "height": {
                "type": "fit"
              }
            },
            "spacing": 6,
            "padding": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "margin": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "shape": {
              "type": "rectangle",
              "corners": {
                "top_leading": 8,
                "top_trailing": 8,
                "bottom_leading": 8,
                "bottom_trailing": 8
              }
            },
            "background": null,
            "border": null,
            "shadow": null
          },
          {
            "type": "stack",
            "id": "stk_103",
            "name": "7. Images keep aspect ratio while clamped",
            "components": [
              {
                "type": "text",
                "id": "txt_098",
                "name": "7. Images keep aspect ratio whil",
                "text_lid": "txt_098",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#111111ff"
                  }
                },
                "font_size": 13,
                "font_weight": "bold",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "text",
                "id": "txt_099",
                "name": "Square image. Left: Fit x Fit wi",
                "text_lid": "txt_099",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#6e6e73ff"
                  }
                },
                "font_size": 11,
                "font_weight": "regular",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "stack",
                "id": "stk_100",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_090",
                    "name": "",
                    "components": [
                      {
                        "type": "image",
                        "id": "img_087",
                        "name": "",
                        "source": {
                          "light": {
                            "original": "https://assets.pawwalls.com/1172568_1774614837_7df8aa27.webp",
                            "webp": "https://assets.pawwalls.com/1172568_1774614837_7df8aa27.webp",
                            "webp_low_res": "https://assets.pawwalls.com/1172568_1774614837_7df8aa27.webp",
                            "heic": "https://assets.pawwalls.com/1172568_1774614837_7df8aa27.heic",
                            "heic_low_res": "https://assets.pawwalls.com/1172568_1774614837_7df8aa27.heic",
                            "width": 1024,
                            "height": 1024
                          }
                        },
                        "fit_mode": "fit",
                        "size": {
                          "width": {
                            "type": "fit",
                            "max": 96
                          },
                          "height": {
                            "type": "fit"
                          }
                        },
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        }
                      },
                      {
                        "type": "image",
                        "id": "img_088",
                        "name": "",
                        "source": {
                          "light": {
                            "original": "https://assets.pawwalls.com/1172568_1774614837_7df8aa27.webp",
                            "webp": "https://assets.pawwalls.com/1172568_1774614837_7df8aa27.webp",
                            "webp_low_res": "https://assets.pawwalls.com/1172568_1774614837_7df8aa27.webp",
                            "heic": "https://assets.pawwalls.com/1172568_1774614837_7df8aa27.heic",
                            "heic_low_res": "https://assets.pawwalls.com/1172568_1774614837_7df8aa27.heic",
                            "width": 1024,
                            "height": 1024
                          }
                        },
                        "fit_mode": "fit",
                        "size": {
                          "width": {
                            "type": "fill",
                            "max": 140
                          },
                          "height": {
                            "type": "fit"
                          }
                        },
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        }
                      },
                      {
                        "type": "image",
                        "id": "img_089",
                        "name": "",
                        "source": {
                          "light": {
                            "original": "https://assets.pawwalls.com/1172568_1774614837_7df8aa27.webp",
                            "webp": "https://assets.pawwalls.com/1172568_1774614837_7df8aa27.webp",
                            "webp_low_res": "https://assets.pawwalls.com/1172568_1774614837_7df8aa27.webp",
                            "heic": "https://assets.pawwalls.com/1172568_1774614837_7df8aa27.heic",
                            "heic_low_res": "https://assets.pawwalls.com/1172568_1774614837_7df8aa27.heic",
                            "width": 1024,
                            "height": 1024
                          }
                        },
                        "fit_mode": "fit",
                        "size": {
                          "width": {
                            "type": "fixed",
                            "value": 80
                          },
                          "height": {
                            "type": "fit",
                            "max": 40
                          }
                        },
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        }
                      }
                    ],
                    "dimension": {
                      "type": "horizontal",
                      "alignment": "top",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              },
              {
                "type": "stack",
                "id": "stk_101",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_093",
                    "name": "",
                    "components": [
                      {
                        "type": "image",
                        "id": "img_091",
                        "name": "min 120 wide, max 60 tall -> conflict, min wins (120x120, distorted only if impossible)",
                        "source": {
                          "light": {
                            "original": "https://assets.pawwalls.com/1172568_1774614837_7df8aa27.webp",
                            "webp": "https://assets.pawwalls.com/1172568_1774614837_7df8aa27.webp",
                            "webp_low_res": "https://assets.pawwalls.com/1172568_1774614837_7df8aa27.webp",
                            "heic": "https://assets.pawwalls.com/1172568_1774614837_7df8aa27.heic",
                            "heic_low_res": "https://assets.pawwalls.com/1172568_1774614837_7df8aa27.heic",
                            "width": 1024,
                            "height": 1024
                          }
                        },
                        "fit_mode": "fit",
                        "size": {
                          "width": {
                            "type": "fit",
                            "min": 120
                          },
                          "height": {
                            "type": "fit",
                            "max": 60
                          }
                        },
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        }
                      },
                      {
                        "type": "stack",
                        "id": "stk_092",
                        "name": "#f4a259ff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill"
                          },
                          "height": {
                            "type": "fixed",
                            "value": 60
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#f4a259ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "horizontal",
                      "alignment": "top",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              },
              {
                "type": "stack",
                "id": "stk_102",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_097",
                    "name": "",
                    "components": [
                      {
                        "type": "image",
                        "id": "img_094",
                        "name": "Fit(min 120) image: must be 120, not a share of the row",
                        "source": {
                          "light": {
                            "original": "https://assets.pawwalls.com/1172568_1774614837_7df8aa27.webp",
                            "webp": "https://assets.pawwalls.com/1172568_1774614837_7df8aa27.webp",
                            "webp_low_res": "https://assets.pawwalls.com/1172568_1774614837_7df8aa27.webp",
                            "heic": "https://assets.pawwalls.com/1172568_1774614837_7df8aa27.heic",
                            "heic_low_res": "https://assets.pawwalls.com/1172568_1774614837_7df8aa27.heic",
                            "width": 1024,
                            "height": 1024
                          }
                        },
                        "fit_mode": "fit",
                        "size": {
                          "width": {
                            "type": "fit",
                            "min": 120
                          },
                          "height": {
                            "type": "fit"
                          }
                        },
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        }
                      },
                      {
                        "type": "image",
                        "id": "img_095",
                        "name": "Fixed 120 reference",
                        "source": {
                          "light": {
                            "original": "https://assets.pawwalls.com/1172568_1774614837_7df8aa27.webp",
                            "webp": "https://assets.pawwalls.com/1172568_1774614837_7df8aa27.webp",
                            "webp_low_res": "https://assets.pawwalls.com/1172568_1774614837_7df8aa27.webp",
                            "heic": "https://assets.pawwalls.com/1172568_1774614837_7df8aa27.heic",
                            "heic_low_res": "https://assets.pawwalls.com/1172568_1774614837_7df8aa27.heic",
                            "width": 1024,
                            "height": 1024
                          }
                        },
                        "fit_mode": "fit",
                        "size": {
                          "width": {
                            "type": "fixed",
                            "value": 120
                          },
                          "height": {
                            "type": "fit"
                          }
                        },
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        }
                      },
                      {
                        "type": "stack",
                        "id": "stk_096",
                        "name": "#f4a259ff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill"
                          },
                          "height": {
                            "type": "fixed",
                            "value": 60
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#f4a259ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "horizontal",
                      "alignment": "top",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              }
            ],
            "dimension": {
              "type": "vertical",
              "alignment": "leading",
              "distribution": "start"
            },
            "size": {
              "width": {
                "type": "fill"
              },
              "height": {
                "type": "fit"
              }
            },
            "spacing": 6,
            "padding": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "margin": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "shape": {
              "type": "rectangle",
              "corners": {
                "top_leading": 8,
                "top_trailing": 8,
                "bottom_leading": 8,
                "bottom_trailing": 8
              }
            },
            "background": null,
            "border": null,
            "shadow": null
          },
          {
            "type": "stack",
            "id": "stk_112",
            "name": "8. Text with min/max widths",
            "components": [
              {
                "type": "text",
                "id": "txt_108",
                "name": "8. Text with min/max widths",
                "text_lid": "txt_108",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#111111ff"
                  }
                },
                "font_size": 13,
                "font_weight": "bold",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "text",
                "id": "txt_109",
                "name": "Top: Fill(max 220) text wraps at",
                "text_lid": "txt_109",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#6e6e73ff"
                  }
                },
                "font_size": 11,
                "font_weight": "regular",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "stack",
                "id": "stk_110",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_106",
                    "name": "",
                    "components": [
                      {
                        "type": "text",
                        "id": "txt_104",
                        "name": "This paragraph is Fill width wit",
                        "text_lid": "txt_104",
                        "color": {
                          "light": {
                            "type": "hex",
                            "value": "#3a3a3cff"
                          }
                        },
                        "font_size": 11,
                        "font_weight": "regular",
                        "horizontal_alignment": "leading",
                        "size": {
                          "width": {
                            "type": "fill",
                            "max": 220
                          },
                          "height": {
                            "type": "fit"
                          }
                        },
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "background_color": {
                          "light": {
                            "type": "hex",
                            "value": "#f8dc78ff"
                          }
                        }
                      },
                      {
                        "type": "stack",
                        "id": "stk_105",
                        "name": "#f4a259ff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill"
                          },
                          "height": {
                            "type": "fixed",
                            "value": 24
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#f4a259ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "horizontal",
                      "alignment": "top",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              },
              {
                "type": "stack",
                "id": "stk_111",
                "name": "",
                "components": [
                  {
                    "type": "text",
                    "id": "txt_107",
                    "name": "short",
                    "text_lid": "txt_107",
                    "color": {
                      "light": {
                        "type": "hex",
                        "value": "#3a3a3cff"
                      }
                    },
                    "font_size": 11,
                    "font_weight": "regular",
                    "horizontal_alignment": "center",
                    "size": {
                      "width": {
                        "type": "fit",
                        "min": 200
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "background_color": {
                      "light": {
                        "type": "hex",
                        "value": "#f8dc78ff"
                      }
                    }
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              }
            ],
            "dimension": {
              "type": "vertical",
              "alignment": "leading",
              "distribution": "start"
            },
            "size": {
              "width": {
                "type": "fill"
              },
              "height": {
                "type": "fit"
              }
            },
            "spacing": 6,
            "padding": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "margin": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "shape": {
              "type": "rectangle",
              "corners": {
                "top_leading": 8,
                "top_trailing": 8,
                "bottom_leading": 8,
                "bottom_trailing": 8
              }
            },
            "background": null,
            "border": null,
            "shadow": null
          },
          {
            "type": "stack",
            "id": "stk_119",
            "name": "9. Margins extend min/max",
            "components": [
              {
                "type": "text",
                "id": "txt_116",
                "name": "9. Margins extend min/max",
                "text_lid": "txt_116",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#111111ff"
                  }
                },
                "font_size": 13,
                "font_weight": "bold",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "text",
                "id": "txt_117",
                "name": "Blue is Fill(max 100) with 16dp ",
                "text_lid": "txt_117",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#6e6e73ff"
                  }
                },
                "font_size": 11,
                "font_weight": "regular",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "stack",
                "id": "stk_118",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_115",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_113",
                        "name": "#576cdbff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill",
                            "max": 100
                          },
                          "height": {
                            "type": "fixed",
                            "value": 48
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 16,
                          "trailing": 16,
                          "top": 16,
                          "bottom": 16
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#576cdbff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_114",
                        "name": "#f4a259ff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill"
                          },
                          "height": {
                            "type": "fixed",
                            "value": 48
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#f4a259ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "horizontal",
                      "alignment": "center",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": {
                      "type": "color",
                      "value": {
                        "light": {
                          "type": "hex",
                          "value": "#ffffffff"
                        }
                      }
                    },
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              }
            ],
            "dimension": {
              "type": "vertical",
              "alignment": "leading",
              "distribution": "start"
            },
            "size": {
              "width": {
                "type": "fill"
              },
              "height": {
                "type": "fit"
              }
            },
            "spacing": 6,
            "padding": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "margin": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "shape": {
              "type": "rectangle",
              "corners": {
                "top_leading": 8,
                "top_trailing": 8,
                "bottom_leading": 8,
                "bottom_trailing": 8
              }
            },
            "background": null,
            "border": null,
            "shadow": null
          },
          {
            "type": "stack",
            "id": "stk_126",
            "name": "10. Overrides add a cap per screen size",
            "components": [
              {
                "type": "text",
                "id": "txt_123",
                "name": "10. Overrides add a cap per scre",
                "text_lid": "txt_123",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#111111ff"
                  }
                },
                "font_size": 13,
                "font_weight": "bold",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "text",
                "id": "txt_124",
                "name": "Blue is Fill with an override: c",
                "text_lid": "txt_124",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#6e6e73ff"
                  }
                },
                "font_size": 11,
                "font_weight": "regular",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "stack",
                "id": "stk_125",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_122",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_120",
                        "name": "#576cdbff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill"
                          },
                          "height": {
                            "type": "fixed",
                            "value": 48
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#576cdbff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null,
                        "overrides": [
                          {
                            "conditions": [
                              {
                                "type": "compact"
                              }
                            ],
                            "properties": {
                              "size": {
                                "width": {
                                  "type": "fill",
                                  "max": 80
                                },
                                "height": {
                                  "type": "fixed",
                                  "value": 48
                                }
                              }
                            }
                          },
                          {
                            "conditions": [
                              {
                                "type": "medium"
                              }
                            ],
                            "properties": {
                              "size": {
                                "width": {
                                  "type": "fill",
                                  "max": 200
                                },
                                "height": {
                                  "type": "fixed",
                                  "value": 48
                                }
                              }
                            }
                          }
                        ]
                      },
                      {
                        "type": "stack",
                        "id": "stk_121",
                        "name": "#f4a259ff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill"
                          },
                          "height": {
                            "type": "fixed",
                            "value": 48
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#f4a259ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "horizontal",
                      "alignment": "center",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              }
            ],
            "dimension": {
              "type": "vertical",
              "alignment": "leading",
              "distribution": "start"
            },
            "size": {
              "width": {
                "type": "fill"
              },
              "height": {
                "type": "fit"
              }
            },
            "spacing": 6,
            "padding": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "margin": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "shape": {
              "type": "rectangle",
              "corners": {
                "top_leading": 8,
                "top_trailing": 8,
                "bottom_leading": 8,
                "bottom_trailing": 8
              }
            },
            "background": null,
            "border": null,
            "shadow": null
          },
          {
            "type": "stack",
            "id": "stk_134",
            "name": "11. Nested Fit(min) does not steal a sibling's Fill space",
            "components": [
              {
                "type": "text",
                "id": "txt_131",
                "name": "11. Nested Fit(min) does not ste",
                "text_lid": "txt_131",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#111111ff"
                  }
                },
                "font_size": 13,
                "font_weight": "bold",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "text",
                "id": "txt_132",
                "name": "Purple is a Fit(min 160) row hol",
                "text_lid": "txt_132",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#6e6e73ff"
                  }
                },
                "font_size": 11,
                "font_weight": "regular",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "stack",
                "id": "stk_133",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_130",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_128",
                        "name": "",
                        "components": [
                          {
                            "type": "stack",
                            "id": "stk_127",
                            "name": "#f8dc78ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 32
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#f8dc78ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          }
                        ],
                        "dimension": {
                          "type": "horizontal",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fit",
                            "min": 160
                          },
                          "height": {
                            "type": "fit"
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 8,
                          "trailing": 8,
                          "top": 8,
                          "bottom": 8
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#9b8fd6ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_129",
                        "name": "#f4a259ff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill"
                          },
                          "height": {
                            "type": "fixed",
                            "value": 48
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#f4a259ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "horizontal",
                      "alignment": "center",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              }
            ],
            "dimension": {
              "type": "vertical",
              "alignment": "leading",
              "distribution": "start"
            },
            "size": {
              "width": {
                "type": "fill"
              },
              "height": {
                "type": "fit"
              }
            },
            "spacing": 6,
            "padding": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "margin": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "shape": {
              "type": "rectangle",
              "corners": {
                "top_leading": 8,
                "top_trailing": 8,
                "bottom_leading": 8,
                "bottom_trailing": 8
              }
            },
            "background": null,
            "border": null,
            "shadow": null
          },
          {
            "type": "stack",
            "id": "stk_153",
            "name": "12. Minimum larger than the parent wins",
            "components": [
              {
                "type": "text",
                "id": "txt_147",
                "name": "12. Minimum larger than the pare",
                "text_lid": "txt_147",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#111111ff"
                  }
                },
                "font_size": 13,
                "font_weight": "bold",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "text",
                "id": "txt_148",
                "name": "Purple row is Fixed 200 wide. Re",
                "text_lid": "txt_148",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#6e6e73ff"
                  }
                },
                "font_size": 11,
                "font_weight": "regular",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "stack",
                "id": "stk_149",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_137",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_136",
                        "name": "",
                        "components": [
                          {
                            "type": "stack",
                            "id": "stk_135",
                            "name": "#d94f5cff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fill",
                                "min": 260
                              },
                              "height": {
                                "type": "fixed",
                                "value": 40
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#d94f5cff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          }
                        ],
                        "dimension": {
                          "type": "horizontal",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fixed",
                            "value": 200
                          },
                          "height": {
                            "type": "fit"
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 4,
                          "trailing": 4,
                          "top": 4,
                          "bottom": 4
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#9b8fd6ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "vertical",
                      "alignment": "leading",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              },
              {
                "type": "stack",
                "id": "stk_150",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_140",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_139",
                        "name": "",
                        "components": [
                          {
                            "type": "stack",
                            "id": "stk_138",
                            "name": "#8fc7a2ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 120
                              },
                              "height": {
                                "type": "fill",
                                "min": 64
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#8fc7a2ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          }
                        ],
                        "dimension": {
                          "type": "horizontal",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill"
                          },
                          "height": {
                            "type": "fixed",
                            "value": 40
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 4,
                          "trailing": 4,
                          "top": 4,
                          "bottom": 4
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#2c3592ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "vertical",
                      "alignment": "leading",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              },
              {
                "type": "stack",
                "id": "stk_151",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_143",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_142",
                        "name": "",
                        "components": [
                          {
                            "type": "stack",
                            "id": "stk_141",
                            "name": "#d94f5cff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fill",
                                "min": 260
                              },
                              "height": {
                                "type": "fixed",
                                "value": 40
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#d94f5cff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          }
                        ],
                        "dimension": {
                          "type": "horizontal",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fixed",
                            "value": 200
                          },
                          "height": {
                            "type": "fit"
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 4,
                          "trailing": 4,
                          "top": 4,
                          "bottom": 4
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 0,
                            "top_trailing": 0,
                            "bottom_leading": 0,
                            "bottom_trailing": 0
                          }
                        },
                        "background": null,
                        "border": {
                          "color": {
                            "light": {
                              "type": "hex",
                              "value": "#2c3592ff"
                            }
                          },
                          "width": 1
                        },
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "vertical",
                      "alignment": "leading",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              },
              {
                "type": "stack",
                "id": "stk_152",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_146",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_145",
                        "name": "",
                        "components": [
                          {
                            "type": "stack",
                            "id": "stk_144",
                            "name": "#8fc7a2ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 120
                              },
                              "height": {
                                "type": "fill",
                                "min": 64
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#8fc7a2ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          }
                        ],
                        "dimension": {
                          "type": "horizontal",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill"
                          },
                          "height": {
                            "type": "fixed",
                            "value": 40
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 4,
                          "trailing": 4,
                          "top": 4,
                          "bottom": 4
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 0,
                            "top_trailing": 0,
                            "bottom_leading": 0,
                            "bottom_trailing": 0
                          }
                        },
                        "background": null,
                        "border": {
                          "color": {
                            "light": {
                              "type": "hex",
                              "value": "#2c3592ff"
                            }
                          },
                          "width": 1
                        },
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "vertical",
                      "alignment": "leading",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              }
            ],
            "dimension": {
              "type": "vertical",
              "alignment": "leading",
              "distribution": "start"
            },
            "size": {
              "width": {
                "type": "fill"
              },
              "height": {
                "type": "fit"
              }
            },
            "spacing": 6,
            "padding": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "margin": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "shape": {
              "type": "rectangle",
              "corners": {
                "top_leading": 8,
                "top_trailing": 8,
                "bottom_leading": 8,
                "bottom_trailing": 8
              }
            },
            "background": null,
            "border": null,
            "shadow": null
          },
          {
            "type": "stack",
            "id": "stk_171",
            "name": "13. SPACE_* with capped Fill children",
            "components": [
              {
                "type": "text",
                "id": "txt_166",
                "name": "13. SPACE_* with capped Fill chi",
                "text_lid": "txt_166",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#111111ff"
                  }
                },
                "font_size": 13,
                "font_weight": "bold",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "text",
                "id": "txt_167",
                "name": "Three Fill(max 60) blocks in a F",
                "text_lid": "txt_167",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#6e6e73ff"
                  }
                },
                "font_size": 11,
                "font_weight": "regular",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "stack",
                "id": "stk_168",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_157",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_154",
                        "name": "#576cdbff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill",
                            "max": 60
                          },
                          "height": {
                            "type": "fixed",
                            "value": 32
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#576cdbff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_155",
                        "name": "#8fc7a2ff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill",
                            "max": 60
                          },
                          "height": {
                            "type": "fixed",
                            "value": 32
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#8fc7a2ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_156",
                        "name": "#d94f5cff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill",
                            "max": 60
                          },
                          "height": {
                            "type": "fixed",
                            "value": 32
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#d94f5cff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "horizontal",
                      "alignment": "center",
                      "distribution": "space_between"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              },
              {
                "type": "stack",
                "id": "stk_169",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_161",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_158",
                        "name": "#576cdbff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill",
                            "max": 60
                          },
                          "height": {
                            "type": "fixed",
                            "value": 32
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#576cdbff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_159",
                        "name": "#8fc7a2ff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill",
                            "max": 60
                          },
                          "height": {
                            "type": "fixed",
                            "value": 32
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#8fc7a2ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_160",
                        "name": "#d94f5cff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill",
                            "max": 60
                          },
                          "height": {
                            "type": "fixed",
                            "value": 32
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#d94f5cff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "horizontal",
                      "alignment": "center",
                      "distribution": "space_around"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              },
              {
                "type": "stack",
                "id": "stk_170",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_165",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_162",
                        "name": "#576cdbff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill",
                            "max": 60
                          },
                          "height": {
                            "type": "fixed",
                            "value": 32
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#576cdbff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_163",
                        "name": "#8fc7a2ff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill",
                            "max": 60
                          },
                          "height": {
                            "type": "fixed",
                            "value": 32
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#8fc7a2ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_164",
                        "name": "#d94f5cff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill",
                            "max": 60
                          },
                          "height": {
                            "type": "fixed",
                            "value": 32
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#d94f5cff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "horizontal",
                      "alignment": "center",
                      "distribution": "space_evenly"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              }
            ],
            "dimension": {
              "type": "vertical",
              "alignment": "leading",
              "distribution": "start"
            },
            "size": {
              "width": {
                "type": "fill"
              },
              "height": {
                "type": "fit"
              }
            },
            "spacing": 6,
            "padding": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "margin": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "shape": {
              "type": "rectangle",
              "corners": {
                "top_leading": 8,
                "top_trailing": 8,
                "bottom_leading": 8,
                "bottom_trailing": 8
              }
            },
            "background": null,
            "border": null,
            "shadow": null
          },
          {
            "type": "stack",
            "id": "stk_177",
            "name": "14. Fit(min) height with centered content",
            "components": [
              {
                "type": "text",
                "id": "txt_174",
                "name": "14. Fit(min) height with centere",
                "text_lid": "txt_174",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#111111ff"
                  }
                },
                "font_size": 13,
                "font_weight": "bold",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "text",
                "id": "txt_175",
                "name": "Purple column is Fit(min 120) ta",
                "text_lid": "txt_175",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#6e6e73ff"
                  }
                },
                "font_size": 11,
                "font_weight": "regular",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "stack",
                "id": "stk_176",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_173",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_172",
                        "name": "#f8dc78ff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fixed",
                            "value": 96
                          },
                          "height": {
                            "type": "fixed",
                            "value": 24
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#f8dc78ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "vertical",
                      "alignment": "center",
                      "distribution": "center"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit",
                        "min": 120
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": {
                      "type": "color",
                      "value": {
                        "light": {
                          "type": "hex",
                          "value": "#9b8fd6ff"
                        }
                      }
                    },
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              }
            ],
            "dimension": {
              "type": "vertical",
              "alignment": "leading",
              "distribution": "start"
            },
            "size": {
              "width": {
                "type": "fill"
              },
              "height": {
                "type": "fit"
              }
            },
            "spacing": 6,
            "padding": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "margin": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "shape": {
              "type": "rectangle",
              "corners": {
                "top_leading": 8,
                "top_trailing": 8,
                "bottom_leading": 8,
                "bottom_trailing": 8
              }
            },
            "background": null,
            "border": null,
            "shadow": null
          },
          {
            "type": "stack",
            "id": "stk_185",
            "name": "15. Fill(min == max) behaves like Fixed",
            "components": [
              {
                "type": "text",
                "id": "txt_182",
                "name": "15. Fill(min == max) behaves lik",
                "text_lid": "txt_182",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#111111ff"
                  }
                },
                "font_size": 13,
                "font_weight": "bold",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "text",
                "id": "txt_183",
                "name": "Blue is Fill(min 96, max 96): ex",
                "text_lid": "txt_183",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#6e6e73ff"
                  }
                },
                "font_size": 11,
                "font_weight": "regular",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "stack",
                "id": "stk_184",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_181",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_178",
                        "name": "#576cdbff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill",
                            "min": 96,
                            "max": 96
                          },
                          "height": {
                            "type": "fixed",
                            "value": 48
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#576cdbff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_179",
                        "name": "#f4a259ff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill"
                          },
                          "height": {
                            "type": "fixed",
                            "value": 48
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#f4a259ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_180",
                        "name": "#8fc7a2ff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill"
                          },
                          "height": {
                            "type": "fixed",
                            "value": 48
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#8fc7a2ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "horizontal",
                      "alignment": "center",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              }
            ],
            "dimension": {
              "type": "vertical",
              "alignment": "leading",
              "distribution": "start"
            },
            "size": {
              "width": {
                "type": "fill"
              },
              "height": {
                "type": "fit"
              }
            },
            "spacing": 6,
            "padding": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "margin": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "shape": {
              "type": "rectangle",
              "corners": {
                "top_leading": 8,
                "top_trailing": 8,
                "bottom_leading": 8,
                "bottom_trailing": 8
              }
            },
            "background": null,
            "border": null,
            "shadow": null
          },
          {
            "type": "stack",
            "id": "stk_192",
            "name": "16. Root-level: Fit(min/max) width stack",
            "components": [
              {
                "type": "text",
                "id": "txt_189",
                "name": "16. Root-level: Fit(min/max) wid",
                "text_lid": "txt_189",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#111111ff"
                  }
                },
                "font_size": 13,
                "font_weight": "bold",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "text",
                "id": "txt_190",
                "name": "Purple column is Fit(min 200, ma",
                "text_lid": "txt_190",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#6e6e73ff"
                  }
                },
                "font_size": 11,
                "font_weight": "regular",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "stack",
                "id": "stk_191",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_188",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_187",
                        "name": "",
                        "components": [
                          {
                            "type": "text",
                            "id": "txt_186",
                            "name": "centered",
                            "text_lid": "txt_186",
                            "color": {
                              "light": {
                                "type": "hex",
                                "value": "#ffffffff"
                              }
                            },
                            "font_size": 11,
                            "font_weight": "regular",
                            "horizontal_alignment": "leading",
                            "size": {
                              "width": {
                                "type": "fit"
                              },
                              "height": {
                                "type": "fit"
                              }
                            },
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            }
                          }
                        ],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "center"
                        },
                        "size": {
                          "width": {
                            "type": "fit",
                            "min": 200,
                            "max": 280
                          },
                          "height": {
                            "type": "fit",
                            "min": 56
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#9b8fd6ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "vertical",
                      "alignment": "center",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              }
            ],
            "dimension": {
              "type": "vertical",
              "alignment": "leading",
              "distribution": "start"
            },
            "size": {
              "width": {
                "type": "fill"
              },
              "height": {
                "type": "fit"
              }
            },
            "spacing": 6,
            "padding": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "margin": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "shape": {
              "type": "rectangle",
              "corners": {
                "top_leading": 8,
                "top_trailing": 8,
                "bottom_leading": 8,
                "bottom_trailing": 8
              }
            },
            "background": null,
            "border": null,
            "shadow": null
          },
          {
            "type": "stack",
            "id": "stk_208",
            "name": "17. Mins exceeding the row: overflow with fixed spacing",
            "components": [
              {
                "type": "text",
                "id": "txt_203",
                "name": "17. Mins exceeding the row: over",
                "text_lid": "txt_203",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#111111ff"
                  }
                },
                "font_size": 13,
                "font_weight": "bold",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "text",
                "id": "txt_204",
                "name": "Row 1 (control): two Fill(min 12",
                "text_lid": "txt_204",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#6e6e73ff"
                  }
                },
                "font_size": 11,
                "font_weight": "regular",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "stack",
                "id": "stk_205",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_195",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_193",
                        "name": "#d94f5cff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill",
                            "min": 120
                          },
                          "height": {
                            "type": "fixed",
                            "value": 40
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#d94f5cff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_194",
                        "name": "#2c3592ff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill",
                            "min": 120
                          },
                          "height": {
                            "type": "fixed",
                            "value": 40
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#2c3592ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "horizontal",
                      "alignment": "center",
                      "distribution": "center"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              },
              {
                "type": "stack",
                "id": "stk_206",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_199",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_198",
                        "name": "",
                        "components": [
                          {
                            "type": "stack",
                            "id": "stk_196",
                            "name": "#d94f5cff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fill",
                                "min": 220
                              },
                              "height": {
                                "type": "fixed",
                                "value": 40
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#d94f5cff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          },
                          {
                            "type": "stack",
                            "id": "stk_197",
                            "name": "#2c3592ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fill",
                                "min": 220
                              },
                              "height": {
                                "type": "fixed",
                                "value": 40
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#2c3592ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          }
                        ],
                        "dimension": {
                          "type": "horizontal",
                          "alignment": "center",
                          "distribution": "center"
                        },
                        "size": {
                          "width": {
                            "type": "fixed",
                            "value": 300
                          },
                          "height": {
                            "type": "fit"
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 4,
                          "trailing": 4,
                          "top": 4,
                          "bottom": 4
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 0,
                            "top_trailing": 0,
                            "bottom_leading": 0,
                            "bottom_trailing": 0
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#9b8fd6ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "vertical",
                      "alignment": "leading",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              },
              {
                "type": "stack",
                "id": "stk_207",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_202",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_200",
                        "name": "#d94f5cff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill",
                            "min": 220
                          },
                          "height": {
                            "type": "fixed",
                            "value": 40
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#d94f5cff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_201",
                        "name": "#2c3592ff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill",
                            "min": 220
                          },
                          "height": {
                            "type": "fixed",
                            "value": 40
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#2c3592ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "horizontal",
                      "alignment": "center",
                      "distribution": "center"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              }
            ],
            "dimension": {
              "type": "vertical",
              "alignment": "leading",
              "distribution": "start"
            },
            "size": {
              "width": {
                "type": "fill"
              },
              "height": {
                "type": "fit"
              }
            },
            "spacing": 6,
            "padding": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "margin": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "shape": {
              "type": "rectangle",
              "corners": {
                "top_leading": 8,
                "top_trailing": 8,
                "bottom_leading": 8,
                "bottom_trailing": 8
              }
            },
            "background": null,
            "border": null,
            "shadow": null
          },
          {
            "type": "stack",
            "id": "stk_216",
            "name": "18. Hidden sibling does not shift constraints",
            "components": [
              {
                "type": "text",
                "id": "txt_213",
                "name": "18. Hidden sibling does not shif",
                "text_lid": "txt_213",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#111111ff"
                  }
                },
                "font_size": 13,
                "font_weight": "bold",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "text",
                "id": "txt_214",
                "name": "Blue Fill(max 60), an invisible ",
                "text_lid": "txt_214",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#6e6e73ff"
                  }
                },
                "font_size": 11,
                "font_weight": "regular",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "stack",
                "id": "stk_215",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_212",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_209",
                        "name": "#576cdbff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill",
                            "max": 60
                          },
                          "height": {
                            "type": "fixed",
                            "value": 48
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#576cdbff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_210",
                        "name": "#8fc7a2ff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill"
                          },
                          "height": {
                            "type": "fixed",
                            "value": 48
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#8fc7a2ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null,
                        "visible": false
                      },
                      {
                        "type": "stack",
                        "id": "stk_211",
                        "name": "#f4a259ff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill"
                          },
                          "height": {
                            "type": "fixed",
                            "value": 48
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#f4a259ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "horizontal",
                      "alignment": "center",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              }
            ],
            "dimension": {
              "type": "vertical",
              "alignment": "leading",
              "distribution": "start"
            },
            "size": {
              "width": {
                "type": "fill"
              },
              "height": {
                "type": "fit"
              }
            },
            "spacing": 6,
            "padding": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "margin": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "shape": {
              "type": "rectangle",
              "corners": {
                "top_leading": 8,
                "top_trailing": 8,
                "bottom_leading": 8,
                "bottom_trailing": 8
              }
            },
            "background": null,
            "border": null,
            "shadow": null
          },
          {
            "type": "stack",
            "id": "stk_236",
            "name": "19. Padding lives INSIDE the constraint (width)",
            "components": [
              {
                "type": "text",
                "id": "txt_231",
                "name": "19. Padding lives INSIDE the con",
                "text_lid": "txt_231",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#111111ff"
                  }
                },
                "font_size": 13,
                "font_weight": "bold",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "text",
                "id": "txt_232",
                "name": "Each pair: a padded stack above ",
                "text_lid": "txt_232",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#6e6e73ff"
                  }
                },
                "font_size": 11,
                "font_weight": "regular",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "stack",
                "id": "stk_233",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_220",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_218",
                        "name": "",
                        "components": [
                          {
                            "type": "stack",
                            "id": "stk_217",
                            "name": "#f8dc78ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fill"
                              },
                              "height": {
                                "type": "fixed",
                                "value": 24
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#f8dc78ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          }
                        ],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fixed",
                            "value": 200
                          },
                          "height": {
                            "type": "fit"
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 20,
                          "trailing": 20,
                          "top": 20,
                          "bottom": 20
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 0,
                            "top_trailing": 0,
                            "bottom_leading": 0,
                            "bottom_trailing": 0
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#9b8fd6ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_219",
                        "name": "reference 200",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fixed",
                            "value": 200
                          },
                          "height": {
                            "type": "fixed",
                            "value": 8
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#2c3592ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "vertical",
                      "alignment": "leading",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 2,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              },
              {
                "type": "stack",
                "id": "stk_234",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_226",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_224",
                        "name": "",
                        "components": [
                          {
                            "type": "stack",
                            "id": "stk_222",
                            "name": "",
                            "components": [
                              {
                                "type": "stack",
                                "id": "stk_221",
                                "name": "#f8dc78ff",
                                "components": [],
                                "dimension": {
                                  "type": "vertical",
                                  "alignment": "center",
                                  "distribution": "start"
                                },
                                "size": {
                                  "width": {
                                    "type": "fill"
                                  },
                                  "height": {
                                    "type": "fixed",
                                    "value": 24
                                  }
                                },
                                "spacing": 8,
                                "padding": {
                                  "leading": 0,
                                  "trailing": 0,
                                  "top": 0,
                                  "bottom": 0
                                },
                                "margin": {
                                  "leading": 0,
                                  "trailing": 0,
                                  "top": 0,
                                  "bottom": 0
                                },
                                "shape": {
                                  "type": "rectangle",
                                  "corners": {
                                    "top_leading": 8,
                                    "top_trailing": 8,
                                    "bottom_leading": 8,
                                    "bottom_trailing": 8
                                  }
                                },
                                "background": {
                                  "type": "color",
                                  "value": {
                                    "light": {
                                      "type": "hex",
                                      "value": "#f8dc78ff"
                                    }
                                  }
                                },
                                "border": null,
                                "shadow": null
                              }
                            ],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fill",
                                "max": 160
                              },
                              "height": {
                                "type": "fit"
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 20,
                              "trailing": 20,
                              "top": 20,
                              "bottom": 20
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 0,
                                "top_trailing": 0,
                                "bottom_leading": 0,
                                "bottom_trailing": 0
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#9b8fd6ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          },
                          {
                            "type": "stack",
                            "id": "stk_223",
                            "name": "#f4a259ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fill"
                              },
                              "height": {
                                "type": "fixed",
                                "value": 24
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#f4a259ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          }
                        ],
                        "dimension": {
                          "type": "horizontal",
                          "alignment": "top",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill"
                          },
                          "height": {
                            "type": "fit"
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": null,
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_225",
                        "name": "reference 160",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fixed",
                            "value": 160
                          },
                          "height": {
                            "type": "fixed",
                            "value": 8
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#2c3592ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "vertical",
                      "alignment": "leading",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 2,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              },
              {
                "type": "stack",
                "id": "stk_235",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_230",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_228",
                        "name": "",
                        "components": [
                          {
                            "type": "stack",
                            "id": "stk_227",
                            "name": "#f8dc78ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 32
                              },
                              "height": {
                                "type": "fixed",
                                "value": 24
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#f8dc78ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          }
                        ],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fit",
                            "min": 200
                          },
                          "height": {
                            "type": "fit"
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 20,
                          "trailing": 20,
                          "top": 20,
                          "bottom": 20
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 0,
                            "top_trailing": 0,
                            "bottom_leading": 0,
                            "bottom_trailing": 0
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#9b8fd6ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_229",
                        "name": "reference 200",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fixed",
                            "value": 200
                          },
                          "height": {
                            "type": "fixed",
                            "value": 8
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#2c3592ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "vertical",
                      "alignment": "leading",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 2,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              }
            ],
            "dimension": {
              "type": "vertical",
              "alignment": "leading",
              "distribution": "start"
            },
            "size": {
              "width": {
                "type": "fill"
              },
              "height": {
                "type": "fit"
              }
            },
            "spacing": 6,
            "padding": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "margin": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "shape": {
              "type": "rectangle",
              "corners": {
                "top_leading": 8,
                "top_trailing": 8,
                "bottom_leading": 8,
                "bottom_trailing": 8
              }
            },
            "background": null,
            "border": null,
            "shadow": null
          },
          {
            "type": "stack",
            "id": "stk_246",
            "name": "20. Padding lives INSIDE the constraint (height)",
            "components": [
              {
                "type": "text",
                "id": "txt_243",
                "name": "20. Padding lives INSIDE the con",
                "text_lid": "txt_243",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#111111ff"
                  }
                },
                "font_size": 13,
                "font_weight": "bold",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "text",
                "id": "txt_244",
                "name": "Left: Fit(min 80) tall with 20 p",
                "text_lid": "txt_244",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#6e6e73ff"
                  }
                },
                "font_size": 11,
                "font_weight": "regular",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "stack",
                "id": "stk_245",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_242",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_238",
                        "name": "",
                        "components": [
                          {
                            "type": "stack",
                            "id": "stk_237",
                            "name": "#f8dc78ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 48
                              },
                              "height": {
                                "type": "fixed",
                                "value": 16
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#f8dc78ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          }
                        ],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fit"
                          },
                          "height": {
                            "type": "fit",
                            "min": 80
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 20,
                          "trailing": 20,
                          "top": 20,
                          "bottom": 20
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 0,
                            "top_trailing": 0,
                            "bottom_leading": 0,
                            "bottom_trailing": 0
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#9b8fd6ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_240",
                        "name": "",
                        "components": [
                          {
                            "type": "stack",
                            "id": "stk_239",
                            "name": "#f8dc78ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 48
                              },
                              "height": {
                                "type": "fixed",
                                "value": 16
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#f8dc78ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          }
                        ],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fit"
                          },
                          "height": {
                            "type": "fixed",
                            "value": 80
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 20,
                          "trailing": 20,
                          "top": 20,
                          "bottom": 20
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 0,
                            "top_trailing": 0,
                            "bottom_leading": 0,
                            "bottom_trailing": 0
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#9b8fd6ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_241",
                        "name": "reference 80",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fixed",
                            "value": 24
                          },
                          "height": {
                            "type": "fixed",
                            "value": 80
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#2c3592ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "horizontal",
                      "alignment": "top",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              }
            ],
            "dimension": {
              "type": "vertical",
              "alignment": "leading",
              "distribution": "start"
            },
            "size": {
              "width": {
                "type": "fill"
              },
              "height": {
                "type": "fit"
              }
            },
            "spacing": 6,
            "padding": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "margin": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "shape": {
              "type": "rectangle",
              "corners": {
                "top_leading": 8,
                "top_trailing": 8,
                "bottom_leading": 8,
                "bottom_trailing": 8
              }
            },
            "background": null,
            "border": null,
            "shadow": null
          },
          {
            "type": "stack",
            "id": "stk_267",
            "name": "21. Overflow policy: clipped vs visible",
            "components": [
              {
                "type": "text",
                "id": "txt_262",
                "name": "21. Overflow policy: clipped vs ",
                "text_lid": "txt_262",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#111111ff"
                  }
                },
                "font_size": 13,
                "font_weight": "bold",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "text",
                "id": "txt_263",
                "name": "Same content as 4 (Fit(max 160) ",
                "text_lid": "txt_263",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#6e6e73ff"
                  }
                },
                "font_size": 11,
                "font_weight": "regular",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "stack",
                "id": "stk_264",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_251",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_250",
                        "name": "",
                        "components": [
                          {
                            "type": "stack",
                            "id": "stk_247",
                            "name": "#f8dc78ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 64
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#f8dc78ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          },
                          {
                            "type": "stack",
                            "id": "stk_248",
                            "name": "#8fc7a2ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 64
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#8fc7a2ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          },
                          {
                            "type": "stack",
                            "id": "stk_249",
                            "name": "#d94f5cff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 64
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#d94f5cff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          }
                        ],
                        "dimension": {
                          "type": "horizontal",
                          "alignment": "center",
                          "distribution": "center"
                        },
                        "size": {
                          "width": {
                            "type": "fit",
                            "max": 160
                          },
                          "height": {
                            "type": "fit"
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 4,
                          "trailing": 4,
                          "top": 4,
                          "bottom": 4
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 0,
                            "top_trailing": 0,
                            "bottom_leading": 0,
                            "bottom_trailing": 0
                          }
                        },
                        "background": null,
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "vertical",
                      "alignment": "center",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              },
              {
                "type": "stack",
                "id": "stk_265",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_256",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_255",
                        "name": "",
                        "components": [
                          {
                            "type": "stack",
                            "id": "stk_252",
                            "name": "#f8dc78ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 64
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#f8dc78ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          },
                          {
                            "type": "stack",
                            "id": "stk_253",
                            "name": "#8fc7a2ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 64
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#8fc7a2ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          },
                          {
                            "type": "stack",
                            "id": "stk_254",
                            "name": "#d94f5cff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 64
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#d94f5cff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          }
                        ],
                        "dimension": {
                          "type": "horizontal",
                          "alignment": "center",
                          "distribution": "center"
                        },
                        "size": {
                          "width": {
                            "type": "fit",
                            "max": 160
                          },
                          "height": {
                            "type": "fit"
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 4,
                          "trailing": 4,
                          "top": 4,
                          "bottom": 4
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 12,
                            "top_trailing": 12,
                            "bottom_leading": 12,
                            "bottom_trailing": 12
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#9b8fd6ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "vertical",
                      "alignment": "center",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              },
              {
                "type": "stack",
                "id": "stk_266",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_261",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_260",
                        "name": "",
                        "components": [
                          {
                            "type": "stack",
                            "id": "stk_257",
                            "name": "#f8dc78ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 64
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#f8dc78ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          },
                          {
                            "type": "stack",
                            "id": "stk_258",
                            "name": "#8fc7a2ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 64
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#8fc7a2ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          },
                          {
                            "type": "stack",
                            "id": "stk_259",
                            "name": "#d94f5cff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 64
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#d94f5cff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          }
                        ],
                        "dimension": {
                          "type": "horizontal",
                          "alignment": "center",
                          "distribution": "center"
                        },
                        "size": {
                          "width": {
                            "type": "fit",
                            "max": 160
                          },
                          "height": {
                            "type": "fit"
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 4,
                          "trailing": 4,
                          "top": 4,
                          "bottom": 4
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 12,
                            "top_trailing": 12,
                            "bottom_leading": 12,
                            "bottom_trailing": 12
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#9b8fd6ff"
                            }
                          }
                        },
                        "border": {
                          "color": {
                            "light": {
                              "type": "hex",
                              "value": "#2c3592ff"
                            }
                          },
                          "width": 1
                        },
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "vertical",
                      "alignment": "center",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              }
            ],
            "dimension": {
              "type": "vertical",
              "alignment": "leading",
              "distribution": "start"
            },
            "size": {
              "width": {
                "type": "fill"
              },
              "height": {
                "type": "fit"
              }
            },
            "spacing": 6,
            "padding": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "margin": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "shape": {
              "type": "rectangle",
              "corners": {
                "top_leading": 8,
                "top_trailing": 8,
                "bottom_leading": 8,
                "bottom_trailing": 8
              }
            },
            "background": null,
            "border": null,
            "shadow": null
          },
          {
            "type": "stack",
            "id": "stk_288",
            "name": "22. Preview-harness replica (Fixed 240 x 72, no padding, no shape)",
            "components": [
              {
                "type": "text",
                "id": "txt_283",
                "name": "22. Preview-harness replica (Fix",
                "text_lid": "txt_283",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#111111ff"
                  }
                },
                "font_size": 13,
                "font_weight": "bold",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "text",
                "id": "txt_284",
                "name": "These mirror the iOS/Android Sta",
                "text_lid": "txt_284",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#6e6e73ff"
                  }
                },
                "font_size": 11,
                "font_weight": "regular",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "stack",
                "id": "stk_285",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_272",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_271",
                        "name": "",
                        "components": [
                          {
                            "type": "stack",
                            "id": "stk_268",
                            "name": "#576cdbff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fill",
                                "max": 60
                              },
                              "height": {
                                "type": "fill"
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#576cdbff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          },
                          {
                            "type": "stack",
                            "id": "stk_269",
                            "name": "#f4a259ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fill"
                              },
                              "height": {
                                "type": "fill"
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#f4a259ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          },
                          {
                            "type": "stack",
                            "id": "stk_270",
                            "name": "#8fc7a2ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fill",
                                "min": 140
                              },
                              "height": {
                                "type": "fill"
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#8fc7a2ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          }
                        ],
                        "dimension": {
                          "type": "horizontal",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fixed",
                            "value": 240
                          },
                          "height": {
                            "type": "fixed",
                            "value": 72
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 0,
                            "top_trailing": 0,
                            "bottom_leading": 0,
                            "bottom_trailing": 0
                          }
                        },
                        "background": null,
                        "border": {
                          "color": {
                            "light": {
                              "type": "hex",
                              "value": "#d94f5cff"
                            }
                          },
                          "width": 1
                        },
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "vertical",
                      "alignment": "leading",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              },
              {
                "type": "stack",
                "id": "stk_286",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_278",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_277",
                        "name": "",
                        "components": [
                          {
                            "type": "stack",
                            "id": "stk_274",
                            "name": "",
                            "components": [
                              {
                                "type": "stack",
                                "id": "stk_273",
                                "name": "#f8dc78ff",
                                "components": [],
                                "dimension": {
                                  "type": "vertical",
                                  "alignment": "center",
                                  "distribution": "start"
                                },
                                "size": {
                                  "width": {
                                    "type": "fixed",
                                    "value": 24
                                  },
                                  "height": {
                                    "type": "fixed",
                                    "value": 24
                                  }
                                },
                                "spacing": 8,
                                "padding": {
                                  "leading": 0,
                                  "trailing": 0,
                                  "top": 0,
                                  "bottom": 0
                                },
                                "margin": {
                                  "leading": 0,
                                  "trailing": 0,
                                  "top": 0,
                                  "bottom": 0
                                },
                                "shape": {
                                  "type": "rectangle",
                                  "corners": {
                                    "top_leading": 8,
                                    "top_trailing": 8,
                                    "bottom_leading": 8,
                                    "bottom_trailing": 8
                                  }
                                },
                                "background": {
                                  "type": "color",
                                  "value": {
                                    "light": {
                                      "type": "hex",
                                      "value": "#f8dc78ff"
                                    }
                                  }
                                },
                                "border": null,
                                "shadow": null
                              }
                            ],
                            "dimension": {
                              "type": "horizontal",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fit",
                                "min": 160
                              },
                              "height": {
                                "type": "fill"
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 0,
                                "top_trailing": 0,
                                "bottom_leading": 0,
                                "bottom_trailing": 0
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#9b8fd6ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          },
                          {
                            "type": "stack",
                            "id": "stk_276",
                            "name": "",
                            "components": [
                              {
                                "type": "stack",
                                "id": "stk_275",
                                "name": "#f8dc78ff",
                                "components": [],
                                "dimension": {
                                  "type": "vertical",
                                  "alignment": "center",
                                  "distribution": "start"
                                },
                                "size": {
                                  "width": {
                                    "type": "fixed",
                                    "value": 24
                                  },
                                  "height": {
                                    "type": "fixed",
                                    "value": 24
                                  }
                                },
                                "spacing": 8,
                                "padding": {
                                  "leading": 0,
                                  "trailing": 0,
                                  "top": 0,
                                  "bottom": 0
                                },
                                "margin": {
                                  "leading": 0,
                                  "trailing": 0,
                                  "top": 0,
                                  "bottom": 0
                                },
                                "shape": {
                                  "type": "rectangle",
                                  "corners": {
                                    "top_leading": 8,
                                    "top_trailing": 8,
                                    "bottom_leading": 8,
                                    "bottom_trailing": 8
                                  }
                                },
                                "background": {
                                  "type": "color",
                                  "value": {
                                    "light": {
                                      "type": "hex",
                                      "value": "#f8dc78ff"
                                    }
                                  }
                                },
                                "border": null,
                                "shadow": null
                              }
                            ],
                            "dimension": {
                              "type": "horizontal",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fit",
                                "min": 160
                              },
                              "height": {
                                "type": "fill"
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 0,
                                "top_trailing": 0,
                                "bottom_leading": 0,
                                "bottom_trailing": 0
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#2c3592ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          }
                        ],
                        "dimension": {
                          "type": "horizontal",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fixed",
                            "value": 240
                          },
                          "height": {
                            "type": "fixed",
                            "value": 72
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 0,
                            "top_trailing": 0,
                            "bottom_leading": 0,
                            "bottom_trailing": 0
                          }
                        },
                        "background": null,
                        "border": {
                          "color": {
                            "light": {
                              "type": "hex",
                              "value": "#d94f5cff"
                            }
                          },
                          "width": 1
                        },
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "vertical",
                      "alignment": "leading",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              },
              {
                "type": "stack",
                "id": "stk_287",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_282",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_281",
                        "name": "",
                        "components": [
                          {
                            "type": "stack",
                            "id": "stk_279",
                            "name": "#576cdbff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fill",
                                "min": 100,
                                "max": 100
                              },
                              "height": {
                                "type": "fill"
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#576cdbff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          },
                          {
                            "type": "stack",
                            "id": "stk_280",
                            "name": "#f4a259ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fill"
                              },
                              "height": {
                                "type": "fill"
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#f4a259ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          }
                        ],
                        "dimension": {
                          "type": "horizontal",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fixed",
                            "value": 240
                          },
                          "height": {
                            "type": "fixed",
                            "value": 72
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 0,
                            "top_trailing": 0,
                            "bottom_leading": 0,
                            "bottom_trailing": 0
                          }
                        },
                        "background": null,
                        "border": {
                          "color": {
                            "light": {
                              "type": "hex",
                              "value": "#d94f5cff"
                            }
                          },
                          "width": 1
                        },
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "vertical",
                      "alignment": "leading",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              }
            ],
            "dimension": {
              "type": "vertical",
              "alignment": "leading",
              "distribution": "start"
            },
            "size": {
              "width": {
                "type": "fill"
              },
              "height": {
                "type": "fit"
              }
            },
            "spacing": 6,
            "padding": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "margin": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "shape": {
              "type": "rectangle",
              "corners": {
                "top_leading": 8,
                "top_trailing": 8,
                "bottom_leading": 8,
                "bottom_trailing": 8
              }
            },
            "background": null,
            "border": null,
            "shadow": null
          },
          {
            "type": "stack",
            "id": "stk_304",
            "name": "23. Text children carry min/max too",
            "components": [
              {
                "type": "text",
                "id": "txt_299",
                "name": "23. Text children carry min/max ",
                "text_lid": "txt_299",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#111111ff"
                  }
                },
                "font_size": 13,
                "font_weight": "bold",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "text",
                "id": "txt_300",
                "name": "Row 1: three TEXT children Fill(",
                "text_lid": "txt_300",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#6e6e73ff"
                  }
                },
                "font_size": 11,
                "font_weight": "regular",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "stack",
                "id": "stk_301",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_292",
                    "name": "",
                    "components": [
                      {
                        "type": "text",
                        "id": "txt_289",
                        "name": "max60",
                        "text_lid": "txt_289",
                        "color": {
                          "light": {
                            "type": "hex",
                            "value": "#ffffffff"
                          }
                        },
                        "font_size": 11,
                        "font_weight": "regular",
                        "horizontal_alignment": "leading",
                        "size": {
                          "width": {
                            "type": "fill",
                            "max": 60
                          },
                          "height": {
                            "type": "fit"
                          }
                        },
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "background_color": {
                          "light": {
                            "type": "hex",
                            "value": "#576cdbff"
                          }
                        }
                      },
                      {
                        "type": "text",
                        "id": "txt_290",
                        "name": "fill",
                        "text_lid": "txt_290",
                        "color": {
                          "light": {
                            "type": "hex",
                            "value": "#3a3a3cff"
                          }
                        },
                        "font_size": 11,
                        "font_weight": "regular",
                        "horizontal_alignment": "leading",
                        "size": {
                          "width": {
                            "type": "fill"
                          },
                          "height": {
                            "type": "fit"
                          }
                        },
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "background_color": {
                          "light": {
                            "type": "hex",
                            "value": "#f4a259ff"
                          }
                        }
                      },
                      {
                        "type": "text",
                        "id": "txt_291",
                        "name": "min140",
                        "text_lid": "txt_291",
                        "color": {
                          "light": {
                            "type": "hex",
                            "value": "#3a3a3cff"
                          }
                        },
                        "font_size": 11,
                        "font_weight": "regular",
                        "horizontal_alignment": "leading",
                        "size": {
                          "width": {
                            "type": "fill",
                            "min": 140
                          },
                          "height": {
                            "type": "fit"
                          }
                        },
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "background_color": {
                          "light": {
                            "type": "hex",
                            "value": "#8fc7a2ff"
                          }
                        }
                      }
                    ],
                    "dimension": {
                      "type": "horizontal",
                      "alignment": "top",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              },
              {
                "type": "stack",
                "id": "stk_302",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_295",
                    "name": "",
                    "components": [
                      {
                        "type": "text",
                        "id": "txt_293",
                        "name": "This text is Fit with min 120 an",
                        "text_lid": "txt_293",
                        "color": {
                          "light": {
                            "type": "hex",
                            "value": "#3a3a3cff"
                          }
                        },
                        "font_size": 11,
                        "font_weight": "regular",
                        "horizontal_alignment": "leading",
                        "size": {
                          "width": {
                            "type": "fit",
                            "min": 120,
                            "max": 200
                          },
                          "height": {
                            "type": "fit"
                          }
                        },
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "background_color": {
                          "light": {
                            "type": "hex",
                            "value": "#f8dc78ff"
                          }
                        }
                      },
                      {
                        "type": "stack",
                        "id": "stk_294",
                        "name": "#f4a259ff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill"
                          },
                          "height": {
                            "type": "fixed",
                            "value": 24
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#f4a259ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "horizontal",
                      "alignment": "top",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              },
              {
                "type": "stack",
                "id": "stk_303",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_298",
                    "name": "",
                    "components": [
                      {
                        "type": "text",
                        "id": "txt_296",
                        "name": "ok",
                        "text_lid": "txt_296",
                        "color": {
                          "light": {
                            "type": "hex",
                            "value": "#3a3a3cff"
                          }
                        },
                        "font_size": 11,
                        "font_weight": "regular",
                        "horizontal_alignment": "leading",
                        "size": {
                          "width": {
                            "type": "fit",
                            "min": 120
                          },
                          "height": {
                            "type": "fit"
                          }
                        },
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "background_color": {
                          "light": {
                            "type": "hex",
                            "value": "#f8dc78ff"
                          }
                        }
                      },
                      {
                        "type": "stack",
                        "id": "stk_297",
                        "name": "#f4a259ff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill"
                          },
                          "height": {
                            "type": "fixed",
                            "value": 24
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#f4a259ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "horizontal",
                      "alignment": "top",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              }
            ],
            "dimension": {
              "type": "vertical",
              "alignment": "leading",
              "distribution": "start"
            },
            "size": {
              "width": {
                "type": "fill"
              },
              "height": {
                "type": "fit"
              }
            },
            "spacing": 6,
            "padding": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "margin": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "shape": {
              "type": "rectangle",
              "corners": {
                "top_leading": 8,
                "top_trailing": 8,
                "bottom_leading": 8,
                "bottom_trailing": 8
              }
            },
            "background": null,
            "border": null,
            "shadow": null
          },
          {
            "type": "stack",
            "id": "stk_317",
            "name": "24. Fill child inside a Fit(min) parent",
            "components": [
              {
                "type": "text",
                "id": "txt_313",
                "name": "24. Fill child inside a Fit(min)",
                "text_lid": "txt_313",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#111111ff"
                  }
                },
                "font_size": 13,
                "font_weight": "bold",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "text",
                "id": "txt_314",
                "name": "Purple row is Fit(min 200) with ",
                "text_lid": "txt_314",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#6e6e73ff"
                  }
                },
                "font_size": 11,
                "font_weight": "regular",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "stack",
                "id": "stk_315",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_308",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_306",
                        "name": "",
                        "components": [
                          {
                            "type": "stack",
                            "id": "stk_305",
                            "name": "#f8dc78ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fill"
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#f8dc78ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          }
                        ],
                        "dimension": {
                          "type": "horizontal",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fit",
                            "min": 200
                          },
                          "height": {
                            "type": "fit"
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 8,
                          "trailing": 8,
                          "top": 8,
                          "bottom": 8
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#9b8fd6ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_307",
                        "name": "#f4a259ff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill"
                          },
                          "height": {
                            "type": "fixed",
                            "value": 48
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#f4a259ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "horizontal",
                      "alignment": "center",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              },
              {
                "type": "stack",
                "id": "stk_316",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_312",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_310",
                        "name": "",
                        "components": [
                          {
                            "type": "stack",
                            "id": "stk_309",
                            "name": "#f8dc78ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fill",
                                "max": 100
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#f8dc78ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          }
                        ],
                        "dimension": {
                          "type": "horizontal",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fit",
                            "min": 200
                          },
                          "height": {
                            "type": "fit"
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 8,
                          "trailing": 8,
                          "top": 8,
                          "bottom": 8
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#9b8fd6ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_311",
                        "name": "#f4a259ff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill"
                          },
                          "height": {
                            "type": "fixed",
                            "value": 48
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#f4a259ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "horizontal",
                      "alignment": "center",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              }
            ],
            "dimension": {
              "type": "vertical",
              "alignment": "leading",
              "distribution": "start"
            },
            "size": {
              "width": {
                "type": "fill"
              },
              "height": {
                "type": "fit"
              }
            },
            "spacing": 6,
            "padding": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "margin": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "shape": {
              "type": "rectangle",
              "corners": {
                "top_leading": 8,
                "top_trailing": 8,
                "bottom_leading": 8,
                "bottom_trailing": 8
              }
            },
            "background": null,
            "border": null,
            "shadow": null
          },
          {
            "type": "stack",
            "id": "stk_334",
            "name": "25. Legacy control: no min/max anywhere",
            "components": [
              {
                "type": "text",
                "id": "txt_329",
                "name": "25. Legacy control: no min/max a",
                "text_lid": "txt_329",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#111111ff"
                  }
                },
                "font_size": 13,
                "font_weight": "bold",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "text",
                "id": "txt_330",
                "name": "Nothing in this section uses min",
                "text_lid": "txt_330",
                "color": {
                  "light": {
                    "type": "hex",
                    "value": "#6e6e73ff"
                  }
                },
                "font_size": 11,
                "font_weight": "regular",
                "horizontal_alignment": "leading",
                "size": {
                  "width": {
                    "type": "fit"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "padding": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                }
              },
              {
                "type": "stack",
                "id": "stk_331",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_321",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_318",
                        "name": "#576cdbff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill"
                          },
                          "height": {
                            "type": "fixed",
                            "value": 40
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#576cdbff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_319",
                        "name": "#f4a259ff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill"
                          },
                          "height": {
                            "type": "fixed",
                            "value": 40
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#f4a259ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      },
                      {
                        "type": "stack",
                        "id": "stk_320",
                        "name": "#2c3592ff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fixed",
                            "value": 48
                          },
                          "height": {
                            "type": "fixed",
                            "value": 40
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#2c3592ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "horizontal",
                      "alignment": "center",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              },
              {
                "type": "stack",
                "id": "stk_332",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_324",
                    "name": "",
                    "components": [
                      {
                        "type": "text",
                        "id": "txt_322",
                        "name": "Fill text, no min or max",
                        "text_lid": "txt_322",
                        "color": {
                          "light": {
                            "type": "hex",
                            "value": "#3a3a3cff"
                          }
                        },
                        "font_size": 11,
                        "font_weight": "regular",
                        "horizontal_alignment": "leading",
                        "size": {
                          "width": {
                            "type": "fill"
                          },
                          "height": {
                            "type": "fit"
                          }
                        },
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "background_color": {
                          "light": {
                            "type": "hex",
                            "value": "#f8dc78ff"
                          }
                        }
                      },
                      {
                        "type": "stack",
                        "id": "stk_323",
                        "name": "#f4a259ff",
                        "components": [],
                        "dimension": {
                          "type": "vertical",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fill"
                          },
                          "height": {
                            "type": "fixed",
                            "value": 40
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#f4a259ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "horizontal",
                      "alignment": "top",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              },
              {
                "type": "stack",
                "id": "stk_333",
                "name": "",
                "components": [
                  {
                    "type": "stack",
                    "id": "stk_328",
                    "name": "",
                    "components": [
                      {
                        "type": "stack",
                        "id": "stk_327",
                        "name": "",
                        "components": [
                          {
                            "type": "stack",
                            "id": "stk_325",
                            "name": "#f8dc78ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 32
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#f8dc78ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          },
                          {
                            "type": "stack",
                            "id": "stk_326",
                            "name": "#f8dc78ff",
                            "components": [],
                            "dimension": {
                              "type": "vertical",
                              "alignment": "center",
                              "distribution": "start"
                            },
                            "size": {
                              "width": {
                                "type": "fixed",
                                "value": 32
                              },
                              "height": {
                                "type": "fixed",
                                "value": 32
                              }
                            },
                            "spacing": 8,
                            "padding": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "margin": {
                              "leading": 0,
                              "trailing": 0,
                              "top": 0,
                              "bottom": 0
                            },
                            "shape": {
                              "type": "rectangle",
                              "corners": {
                                "top_leading": 8,
                                "top_trailing": 8,
                                "bottom_leading": 8,
                                "bottom_trailing": 8
                              }
                            },
                            "background": {
                              "type": "color",
                              "value": {
                                "light": {
                                  "type": "hex",
                                  "value": "#f8dc78ff"
                                }
                              }
                            },
                            "border": null,
                            "shadow": null
                          }
                        ],
                        "dimension": {
                          "type": "horizontal",
                          "alignment": "center",
                          "distribution": "start"
                        },
                        "size": {
                          "width": {
                            "type": "fit"
                          },
                          "height": {
                            "type": "fit"
                          }
                        },
                        "spacing": 8,
                        "padding": {
                          "leading": 4,
                          "trailing": 4,
                          "top": 4,
                          "bottom": 4
                        },
                        "margin": {
                          "leading": 0,
                          "trailing": 0,
                          "top": 0,
                          "bottom": 0
                        },
                        "shape": {
                          "type": "rectangle",
                          "corners": {
                            "top_leading": 8,
                            "top_trailing": 8,
                            "bottom_leading": 8,
                            "bottom_trailing": 8
                          }
                        },
                        "background": {
                          "type": "color",
                          "value": {
                            "light": {
                              "type": "hex",
                              "value": "#9b8fd6ff"
                            }
                          }
                        },
                        "border": null,
                        "shadow": null
                      }
                    ],
                    "dimension": {
                      "type": "vertical",
                      "alignment": "center",
                      "distribution": "start"
                    },
                    "size": {
                      "width": {
                        "type": "fill"
                      },
                      "height": {
                        "type": "fit"
                      }
                    },
                    "spacing": 8,
                    "padding": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "margin": {
                      "leading": 0,
                      "trailing": 0,
                      "top": 0,
                      "bottom": 0
                    },
                    "shape": {
                      "type": "rectangle",
                      "corners": {
                        "top_leading": 8,
                        "top_trailing": 8,
                        "bottom_leading": 8,
                        "bottom_trailing": 8
                      }
                    },
                    "background": null,
                    "border": null,
                    "shadow": null
                  }
                ],
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "start"
                },
                "size": {
                  "width": {
                    "type": "fill"
                  },
                  "height": {
                    "type": "fit"
                  }
                },
                "spacing": 8,
                "padding": {
                  "leading": 8,
                  "trailing": 8,
                  "top": 8,
                  "bottom": 8
                },
                "margin": {
                  "leading": 0,
                  "trailing": 0,
                  "top": 0,
                  "bottom": 0
                },
                "shape": {
                  "type": "rectangle",
                  "corners": {
                    "top_leading": 10,
                    "top_trailing": 10,
                    "bottom_leading": 10,
                    "bottom_trailing": 10
                  }
                },
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#f6f6f8ff"
                    }
                  }
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#c9c9d1ff"
                    }
                  },
                  "width": 1
                },
                "shadow": null
              }
            ],
            "dimension": {
              "type": "vertical",
              "alignment": "leading",
              "distribution": "start"
            },
            "size": {
              "width": {
                "type": "fill"
              },
              "height": {
                "type": "fit"
              }
            },
            "spacing": 6,
            "padding": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "margin": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "shape": {
              "type": "rectangle",
              "corners": {
                "top_leading": 8,
                "top_trailing": 8,
                "bottom_leading": 8,
                "bottom_trailing": 8
              }
            },
            "background": null,
            "border": null,
            "shadow": null
          },
          {
            "type": "stack",
            "id": "stk_341",
            "name": "footer spacer",
            "components": [],
            "dimension": {
              "type": "vertical",
              "alignment": "center",
              "distribution": "start"
            },
            "size": {
              "width": {
                "type": "fill"
              },
              "height": {
                "type": "fixed",
                "value": 96
              }
            },
            "spacing": 8,
            "padding": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "margin": {
              "leading": 0,
              "trailing": 0,
              "top": 0,
              "bottom": 0
            },
            "shape": {
              "type": "rectangle",
              "corners": {
                "top_leading": 8,
                "top_trailing": 8,
                "bottom_leading": 8,
                "bottom_trailing": 8
              }
            },
            "background": {
              "type": "color",
              "value": {
                "light": {
                  "type": "hex",
                  "value": "#00000000"
                }
              }
            },
            "border": null,
            "shadow": null
          }
        ],
        "dimension": {
          "type": "vertical",
          "alignment": "leading",
          "distribution": "start"
        },
        "size": {
          "width": {
            "type": "fill"
          },
          "height": {
            "type": "fill"
          }
        },
        "spacing": 20,
        "padding": {
          "leading": 16,
          "trailing": 16,
          "top": 16,
          "bottom": 16
        },
        "margin": {
          "leading": 0,
          "trailing": 0,
          "top": 0,
          "bottom": 0
        },
        "shape": {
          "type": "rectangle",
          "corners": {
            "top_leading": 0,
            "top_trailing": 0,
            "bottom_leading": 0,
            "bottom_trailing": 0
          }
        },
        "background": null,
        "border": null,
        "shadow": null
      },
      "sticky_footer": {
        "id": "6f0e84bf7a",
        "stack": {
          "background": {
            "type": "color",
            "value": {
              "light": {
                "type": "hex",
                "value": "#ffffffff"
              }
            }
          },
          "background_color": null,
          "border": null,
          "components": [
            {
              "id": "d6ef0ab068",
              "name": "Purchase",
              "stack": {
                "background": {
                  "type": "color",
                  "value": {
                    "light": {
                      "type": "hex",
                      "value": "#007affff"
                    }
                  }
                },
                "background_color": null,
                "border": null,
                "components": [
                  {
                    "background_color": null,
                    "color": {
                      "light": {
                        "type": "hex",
                        "value": "#ffffffff"
                      }
                    },
                    "font_name": null,
                    "font_size": 16,
                    "font_weight": "semibold",
                    "horizontal_alignment": "center",
                    "id": "792d3770d4",
                    "margin": {
                      "bottom": 0,
                      "leading": 0,
                      "top": 0,
                      "trailing": 0
                    },
                    "padding": {
                      "bottom": 0,
                      "leading": 0,
                      "top": 0,
                      "trailing": 0
                    },
                    "size": {
                      "height": {
                        "type": "fit",
                        "value": null
                      },
                      "width": {
                        "type": "fill",
                        "value": null
                      }
                    },
                    "text_lid": "459ae28186",
                    "type": "text"
                  }
                ],
                "dimension": {
                  "alignment": "center",
                  "distribution": "center",
                  "type": "horizontal"
                },
                "id": "5045d1884f",
                "margin": {
                  "bottom": 0,
                  "leading": 0,
                  "top": 0,
                  "trailing": 0
                },
                "padding": {
                  "bottom": 14,
                  "leading": 8,
                  "top": 14,
                  "trailing": 8
                },
                "shadow": null,
                "shape": {
                  "type": "pill"
                },
                "size": {
                  "height": {
                    "type": "fit",
                    "value": null
                  },
                  "width": {
                    "type": "fill",
                    "value": null
                  }
                },
                "spacing": 0,
                "type": "stack"
              },
              "triggers": {
                "on_purchase_press": "purchase_btn_d6ef0ab068"
              },
              "type": "purchase_button"
            },
            {
              "action": {
                "destination": "sheet",
                "sheet": {
                  "background": {
                    "type": "color",
                    "value": {
                      "light": {
                        "type": "hex",
                        "value": "#FFFFFFFF"
                      }
                    }
                  },
                  "background_blur": true,
                  "id": "SqbpZk_vFi",
                  "name": "",
                  "position": "bottom",
                  "size": {
                    "height": {
                      "type": "fit",
                      "value": null
                    },
                    "width": {
                      "type": "fill",
                      "value": null
                    }
                  },
                  "stack": {
                    "background": {
                      "type": "color",
                      "value": {
                        "light": {
                          "type": "hex",
                          "value": "#FFFFFFFF"
                        }
                      }
                    },
                    "background_color": null,
                    "badge": null,
                    "border": null,
                    "components": [
                      {
                        "background": null,
                        "background_color": null,
                        "border": null,
                        "components": [
                          {
                            "background": null,
                            "background_color": null,
                            "border": null,
                            "components": [
                              {
                                "background": {
                                  "type": "color",
                                  "value": {
                                    "light": {
                                      "type": "hex",
                                      "value": "#576cdbff"
                                    }
                                  }
                                },
                                "background_color": null,
                                "border": null,
                                "components": [],
                                "dimension": {
                                  "alignment": "center",
                                  "distribution": "center",
                                  "type": "vertical"
                                },
                                "id": "7ca1c1e684",
                                "margin": {
                                  "bottom": 0,
                                  "leading": 0,
                                  "top": 0,
                                  "trailing": 0
                                },
                                "name": "Swatch",
                                "padding": {
                                  "bottom": 0,
                                  "leading": 0,
                                  "top": 0,
                                  "trailing": 0
                                },
                                "shadow": null,
                                "shape": {
                                  "corners": {
                                    "bottom_leading": 12,
                                    "bottom_trailing": 12,
                                    "top_leading": 12,
                                    "top_trailing": 12
                                  },
                                  "type": "rectangle"
                                },
                                "size": {
                                  "height": {
                                    "type": "fit",
                                    "value": null,
                                    "min": 88,
                                    "max": 110
                                  },
                                  "width": {
                                    "type": "fill",
                                    "value": null,
                                    "min": 120,
                                    "max": 240
                                  }
                                },
                                "spacing": 0,
                                "type": "stack"
                              },
                              {
                                "background": {
                                  "type": "color",
                                  "value": {
                                    "light": {
                                      "type": "hex",
                                      "value": "#f4a259ff"
                                    }
                                  }
                                },
                                "background_color": null,
                                "border": null,
                                "components": [],
                                "dimension": {
                                  "alignment": "center",
                                  "distribution": "center",
                                  "type": "vertical"
                                },
                                "id": "3aca5540f8",
                                "margin": {
                                  "bottom": 0,
                                  "leading": 0,
                                  "top": 0,
                                  "trailing": 0
                                },
                                "name": "Swatch",
                                "padding": {
                                  "bottom": 0,
                                  "leading": 0,
                                  "top": 0,
                                  "trailing": 0
                                },
                                "shadow": null,
                                "shape": {
                                  "corners": {
                                    "bottom_leading": 12,
                                    "bottom_trailing": 12,
                                    "top_leading": 12,
                                    "top_trailing": 12
                                  },
                                  "type": "rectangle"
                                },
                                "size": {
                                  "height": {
                                    "type": "fixed",
                                    "value": 88
                                  },
                                  "width": {
                                    "type": "fixed",
                                    "value": 88
                                  }
                                },
                                "spacing": 0,
                                "type": "stack"
                              }
                            ],
                            "dimension": {
                              "alignment": "center",
                              "distribution": "start",
                              "type": "horizontal"
                            },
                            "id": "354b97f279",
                            "margin": {
                              "bottom": 0,
                              "leading": 0,
                              "top": 0,
                              "trailing": 0
                            },
                            "name": "Row 1",
                            "padding": {
                              "bottom": 0,
                              "leading": 0,
                              "top": 0,
                              "trailing": 0
                            },
                            "shadow": null,
                            "shape": null,
                            "size": {
                              "height": {
                                "type": "fit",
                                "value": null
                              },
                              "width": {
                                "type": "fill",
                                "value": null
                              }
                            },
                            "spacing": 8,
                            "type": "stack"
                          },
                          {
                            "background": null,
                            "background_color": null,
                            "border": null,
                            "components": [
                              {
                                "background": {
                                  "type": "color",
                                  "value": {
                                    "light": {
                                      "type": "hex",
                                      "value": "#1c1c1eff"
                                    }
                                  }
                                },
                                "background_color": null,
                                "border": null,
                                "components": [],
                                "dimension": {
                                  "alignment": "center",
                                  "distribution": "center",
                                  "type": "vertical"
                                },
                                "id": "6401b2cda6",
                                "margin": {
                                  "bottom": 0,
                                  "leading": 0,
                                  "top": 0,
                                  "trailing": 0
                                },
                                "name": "Swatch",
                                "padding": {
                                  "bottom": 0,
                                  "leading": 0,
                                  "top": 0,
                                  "trailing": 0
                                },
                                "shadow": null,
                                "shape": {
                                  "corners": {
                                    "bottom_leading": 12,
                                    "bottom_trailing": 12,
                                    "top_leading": 12,
                                    "top_trailing": 12
                                  },
                                  "type": "rectangle"
                                },
                                "size": {
                                  "height": {
                                    "type": "fit",
                                    "value": null,
                                    "min": 120,
                                    "max": 140
                                  },
                                  "width": {
                                    "type": "fit",
                                    "value": null,
                                    "min": 64,
                                    "max": 96
                                  }
                                },
                                "spacing": 0,
                                "type": "stack"
                              },
                              {
                                "background": null,
                                "background_color": null,
                                "border": null,
                                "components": [
                                  {
                                    "background": {
                                      "type": "color",
                                      "value": {
                                        "light": {
                                          "type": "hex",
                                          "value": "#8ec5a1ff"
                                        }
                                      }
                                    },
                                    "background_color": null,
                                    "border": null,
                                    "components": [],
                                    "dimension": {
                                      "alignment": "center",
                                      "distribution": "center",
                                      "type": "vertical"
                                    },
                                    "id": "472e2496e8",
                                    "margin": {
                                      "bottom": 0,
                                      "leading": 0,
                                      "top": 0,
                                      "trailing": 0
                                    },
                                    "name": "Swatch",
                                    "padding": {
                                      "bottom": 0,
                                      "leading": 0,
                                      "top": 0,
                                      "trailing": 0
                                    },
                                    "shadow": null,
                                    "shape": {
                                      "corners": {
                                        "bottom_leading": 12,
                                        "bottom_trailing": 12,
                                        "top_leading": 12,
                                        "top_trailing": 12
                                      },
                                      "type": "rectangle"
                                    },
                                    "size": {
                                      "height": {
                                        "type": "fill",
                                        "value": null
                                      },
                                      "width": {
                                        "type": "fill",
                                        "value": null
                                      }
                                    },
                                    "spacing": 0,
                                    "type": "stack"
                                  },
                                  {
                                    "background": {
                                      "type": "color",
                                      "value": {
                                        "light": {
                                          "type": "hex",
                                          "value": "#e9e9ebff"
                                        }
                                      }
                                    },
                                    "background_color": null,
                                    "border": null,
                                    "components": [],
                                    "dimension": {
                                      "alignment": "center",
                                      "distribution": "center",
                                      "type": "vertical"
                                    },
                                    "id": "d54a056bc1",
                                    "margin": {
                                      "bottom": 0,
                                      "leading": 0,
                                      "top": 0,
                                      "trailing": 0
                                    },
                                    "name": "Swatch",
                                    "padding": {
                                      "bottom": 0,
                                      "leading": 0,
                                      "top": 0,
                                      "trailing": 0
                                    },
                                    "shadow": null,
                                    "shape": {
                                      "corners": {
                                        "bottom_leading": 12,
                                        "bottom_trailing": 12,
                                        "top_leading": 12,
                                        "top_trailing": 12
                                      },
                                      "type": "rectangle"
                                    },
                                    "size": {
                                      "height": {
                                        "type": "fill",
                                        "value": null,
                                        "min": 48,
                                        "max": 64
                                      },
                                      "width": {
                                        "type": "fill",
                                        "value": null,
                                        "min": 120,
                                        "max": 240
                                      }
                                    },
                                    "spacing": 0,
                                    "type": "stack"
                                  }
                                ],
                                "dimension": {
                                  "alignment": "center",
                                  "distribution": "start",
                                  "type": "vertical"
                                },
                                "id": "72c2bb3286",
                                "margin": {
                                  "bottom": 0,
                                  "leading": 0,
                                  "top": 0,
                                  "trailing": 0
                                },
                                "name": "Column",
                                "padding": {
                                  "bottom": 0,
                                  "leading": 0,
                                  "top": 0,
                                  "trailing": 0
                                },
                                "shadow": null,
                                "shape": null,
                                "size": {
                                  "height": {
                                    "type": "fit",
                                    "value": null,
                                    "min": 120,
                                    "max": 160
                                  },
                                  "width": {
                                    "type": "fill",
                                    "value": null,
                                    "min": 120,
                                    "max": 240
                                  }
                                },
                                "spacing": 8,
                                "type": "stack"
                              },
                              {
                                "background": {
                                  "type": "color",
                                  "value": {
                                    "light": {
                                      "type": "hex",
                                      "value": "#d5495aff"
                                    }
                                  }
                                },
                                "background_color": null,
                                "border": null,
                                "components": [],
                                "dimension": {
                                  "alignment": "center",
                                  "distribution": "center",
                                  "type": "vertical"
                                },
                                "id": "33287404bd",
                                "margin": {
                                  "bottom": 0,
                                  "leading": 0,
                                  "top": 0,
                                  "trailing": 0
                                },
                                "name": "Swatch",
                                "padding": {
                                  "bottom": 0,
                                  "leading": 0,
                                  "top": 0,
                                  "trailing": 0
                                },
                                "shadow": null,
                                "shape": {
                                  "corners": {
                                    "bottom_leading": 12,
                                    "bottom_trailing": 12,
                                    "top_leading": 12,
                                    "top_trailing": 12
                                  },
                                  "type": "rectangle"
                                },
                                "size": {
                                  "height": {
                                    "type": "fill",
                                    "value": null,
                                    "max": 120
                                  },
                                  "width": {
                                    "type": "fill",
                                    "value": null,
                                    "max": 40
                                  }
                                },
                                "spacing": 0,
                                "type": "stack"
                              }
                            ],
                            "dimension": {
                              "alignment": "center",
                              "distribution": "start",
                              "type": "horizontal"
                            },
                            "id": "05156c84a1",
                            "margin": {
                              "bottom": 0,
                              "leading": 0,
                              "top": 0,
                              "trailing": 0
                            },
                            "name": "Row 2",
                            "padding": {
                              "bottom": 0,
                              "leading": 0,
                              "top": 0,
                              "trailing": 0
                            },
                            "shadow": null,
                            "shape": null,
                            "size": {
                              "height": {
                                "type": "fit",
                                "value": null
                              },
                              "width": {
                                "type": "fill",
                                "value": null
                              }
                            },
                            "spacing": 8,
                            "type": "stack"
                          },
                          {
                            "background": null,
                            "background_color": null,
                            "border": null,
                            "components": [
                              {
                                "background": {
                                  "type": "color",
                                  "value": {
                                    "light": {
                                      "type": "hex",
                                      "value": "#2f3e9eff"
                                    }
                                  }
                                },
                                "background_color": null,
                                "border": null,
                                "components": [],
                                "dimension": {
                                  "alignment": "center",
                                  "distribution": "center",
                                  "type": "vertical"
                                },
                                "id": "cf8ecc87e3",
                                "margin": {
                                  "bottom": 0,
                                  "leading": 0,
                                  "top": 0,
                                  "trailing": 0
                                },
                                "name": "Swatch",
                                "padding": {
                                  "bottom": 0,
                                  "leading": 0,
                                  "top": 0,
                                  "trailing": 0
                                },
                                "shadow": null,
                                "shape": {
                                  "corners": {
                                    "bottom_leading": 12,
                                    "bottom_trailing": 12,
                                    "top_leading": 12,
                                    "top_trailing": 12
                                  },
                                  "type": "rectangle"
                                },
                                "size": {
                                  "height": {
                                    "type": "fit",
                                    "value": null,
                                    "min": 56,
                                    "max": 72
                                  },
                                  "width": {
                                    "type": "fill",
                                    "value": null,
                                    "min": 80
                                  }
                                },
                                "spacing": 0,
                                "type": "stack"
                              },
                              {
                                "background": {
                                  "type": "color",
                                  "value": {
                                    "light": {
                                      "type": "hex",
                                      "value": "#f7d774ff"
                                    }
                                  }
                                },
                                "background_color": null,
                                "border": null,
                                "components": [],
                                "dimension": {
                                  "alignment": "center",
                                  "distribution": "center",
                                  "type": "vertical"
                                },
                                "id": "a71b2bba67",
                                "margin": {
                                  "bottom": 0,
                                  "leading": 0,
                                  "top": 0,
                                  "trailing": 0
                                },
                                "name": "Swatch",
                                "padding": {
                                  "bottom": 0,
                                  "leading": 0,
                                  "top": 0,
                                  "trailing": 0
                                },
                                "shadow": null,
                                "shape": {
                                  "corners": {
                                    "bottom_leading": 12,
                                    "bottom_trailing": 12,
                                    "top_leading": 12,
                                    "top_trailing": 12
                                  },
                                  "type": "rectangle"
                                },
                                "size": {
                                  "height": {
                                    "type": "fixed",
                                    "value": 56
                                  },
                                  "width": {
                                    "type": "fill",
                                    "value": null
                                  }
                                },
                                "spacing": 0,
                                "type": "stack"
                              },
                              {
                                "background": {
                                  "type": "color",
                                  "value": {
                                    "light": {
                                      "type": "hex",
                                      "value": "#9b8cd8ff"
                                    }
                                  }
                                },
                                "background_color": null,
                                "border": null,
                                "components": [],
                                "dimension": {
                                  "alignment": "center",
                                  "distribution": "center",
                                  "type": "vertical"
                                },
                                "id": "0cc864f1b8",
                                "margin": {
                                  "bottom": 0,
                                  "leading": 0,
                                  "top": 0,
                                  "trailing": 0
                                },
                                "name": "Swatch",
                                "padding": {
                                  "bottom": 0,
                                  "leading": 0,
                                  "top": 0,
                                  "trailing": 0
                                },
                                "shadow": null,
                                "shape": {
                                  "corners": {
                                    "bottom_leading": 12,
                                    "bottom_trailing": 12,
                                    "top_leading": 12,
                                    "top_trailing": 12
                                  },
                                  "type": "rectangle"
                                },
                                "size": {
                                  "height": {
                                    "type": "fit",
                                    "value": null,
                                    "min": 56,
                                    "max": 72
                                  },
                                  "width": {
                                    "type": "fill",
                                    "value": null,
                                    "min": 80,
                                    "max": 160
                                  }
                                },
                                "spacing": 0,
                                "type": "stack"
                              }
                            ],
                            "dimension": {
                              "alignment": "center",
                              "distribution": "start",
                              "type": "horizontal"
                            },
                            "id": "f072a033ca",
                            "margin": {
                              "bottom": 0,
                              "leading": 0,
                              "top": 0,
                              "trailing": 0
                            },
                            "name": "Row 3",
                            "padding": {
                              "bottom": 0,
                              "leading": 0,
                              "top": 0,
                              "trailing": 0
                            },
                            "shadow": null,
                            "shape": null,
                            "size": {
                              "height": {
                                "type": "fit",
                                "value": null
                              },
                              "width": {
                                "type": "fill",
                                "value": null
                              }
                            },
                            "spacing": 8,
                            "type": "stack"
                          }
                        ],
                        "dimension": {
                          "alignment": "center",
                          "distribution": "start",
                          "type": "vertical"
                        },
                        "id": "87ae6a97az",
                        "margin": {
                          "bottom": 0,
                          "leading": 0,
                          "top": 0,
                          "trailing": 0
                        },
                        "name": "Color grid",
                        "padding": {
                          "bottom": 0,
                          "leading": 0,
                          "top": 0,
                          "trailing": 0
                        },
                        "shadow": null,
                        "shape": null,
                        "size": {
                          "height": {
                            "type": "fit",
                            "value": null
                          },
                          "width": {
                            "type": "fill",
                            "value": null
                          }
                        },
                        "spacing": 8,
                        "type": "stack"
                      }
                    ],
                    "dimension": {
                      "alignment": "center",
                      "distribution": "center",
                      "type": "vertical"
                    },
                    "id": "efodwqen80",
                    "margin": {
                      "bottom": 90,
                      "leading": 30,
                      "top": 30,
                      "trailing": 30
                    },
                    "name": "Sheet Content",
                    "padding": {
                      "bottom": 0,
                      "leading": 0,
                      "top": 0,
                      "trailing": 0
                    },
                    "shadow": null,
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
                        "type": "fit",
                        "value": null
                      },
                      "width": {
                        "type": "fill",
                        "value": null
                      }
                    },
                    "spacing": 0,
                    "type": "stack"
                  },
                  "type": "sheet"
                },
                "type": "navigate_to"
              },
              "id": "YMVqClL2mI",
              "name": "",
              "stack": {
                "background": null,
                "background_color": null,
                "badge": null,
                "border": null,
                "components": [
                  {
                    "background_color": null,
                    "color": {
                      "light": {
                        "type": "hex",
                        "value": "#000000"
                      }
                    },
                    "font_name": null,
                    "font_size": 14,
                    "font_weight": "regular",
                    "font_weight_int": 400,
                    "horizontal_alignment": "leading",
                    "id": "ekWn2ONx1A",
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
                        "type": "fit",
                        "value": null
                      },
                      "width": {
                        "type": "fit",
                        "value": null
                      }
                    },
                    "text_lid": "T5x1UVdvM2",
                    "type": "text"
                  }
                ],
                "dimension": {
                  "alignment": "leading",
                  "distribution": "start",
                  "type": "vertical"
                },
                "id": "Uv2Tz6NJSk",
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
                "shadow": null,
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
                    "type": "fit",
                    "value": null
                  },
                  "width": {
                    "type": "fit",
                    "value": null
                  }
                },
                "spacing": 0,
                "type": "stack"
              },
              "transition": null,
              "type": "button"
            }
          ],
          "dimension": {
            "alignment": "center",
            "distribution": "start",
            "type": "vertical"
          },
          "id": "f77eb95d0d",
          "margin": {
            "bottom": 0,
            "leading": 0,
            "top": 0,
            "trailing": 0
          },
          "name": "Footer",
          "padding": {
            "bottom": 8,
            "leading": 20,
            "top": 12,
            "trailing": 20
          },
          "shadow": null,
          "shape": null,
          "size": {
            "height": {
              "type": "fit",
              "value": null
            },
            "width": {
              "type": "fill",
              "value": null
            }
          },
          "spacing": 10,
          "type": "stack"
        },
        "type": "footer"
      }
    }
  },
  "components_localizations": {
    "en_US": {
      "26f14f69a5": "Full access to every feature",
      "2DvRJ0aM7N": "Annual",
      "2VLIIswRZx": "",
      "3J2FhWGSLV": "",
      "459ae28186": "Continue",
      "6fd5763a41": "No ads, ever",
      "91c34f5527": "Cancel anytime in seconds",
      "A870ksmypI": "Annual",
      "BZO3Uemnzt": "{{ product.price_per_period_abbreviated }}",
      "BeWd8-Zv6p": "Weekly",
      "Fdu-j2FJtW": "{{ product.relative_discount }} OFF",
      "K_k-H_b6sT": "{{ product.price_per_period_abbreviated }}",
      "R5RXRIFSJv": "Start {{ product.offer_period_with_unit }} free trial",
      "T5x1UVdvM2": "show me the sheet",
      "UBaMKRd4dq": "Monthly",
      "YI2QVlgend": "{{ product.period_in_months }} mo \u2022 {{ product.price_per_month }}/mo",
      "ZIjuTJdTju": "View all plans",
      "__JWOGGkDk": "",
      "_jqsRFBCVY": "Continue",
      "c89439af01": "{{ product.price_per_period }} \u2022 {{ product.price_per_month }}/mo",
      "fld33jPUeB": "Monthly",
      "g6yPPFPG6E": "",
      "gyGgyXh0bb": "{{ product.period_in_months }} mo \u2022 {{ product.price_per_month }}/mo",
      "rSJpV1A8nE": "weekly",
      "s27ru42J4g": "{{ product.periodly | capitalize }}",
      "xnjZ7qCTP-": "{{ product.periodly | capitalize }}",
      "txt_005": "1. Capped Fill sibling redistributes leftover",
      "txt_006": "Row: Fill(max 60) | Fill | Fill(min 140). Blue is exactly 60, green at least 140, orange gets the rest.",
      "txt_009": "hi",
      "txt_013": "this text is long enough to hit the maximum width",
      "txt_017": "2. Fit(min/max) child next to a Fill sibling",
      "txt_018": "Blue is Fit(min 100, max 160) around text. Short text -> 100 wide, text centered. Long text -> capped at 160 and wraps. Orange fills the rest.",
      "txt_037": "3. Fit(min) stack hugs its minimum with SPACE_* distributions",
      "txt_038": "Purple row is Fit(min 240) with three 32dp blocks. It must be 240 wide (not full width) with the space distributed inside. Rows: SPACE_BETWEEN, SPACE_AROUND, SPACE_EVENLY.",
      "txt_058": "4. Fit(max) smaller than content: overflow arrangement",
      "txt_059": "Purple row is Fit(max 160) holding three 64dp blocks (192 + spacing). Content overflows the purple bounds; anchored START, CENTER, END respectively.",
      "txt_068": "5. Vertical: capped and floored Fill heights",
      "txt_069": "Column is Fixed 200 tall: Fill(max 40) | Fill | Fill(min 90). Blue is 40, green at least 90, orange the remainder.",
      "txt_082": "6. Cross-axis Fill under the root scroll (the red-block bug)",
      "txt_083": "Fit-height row inside the scroll: black is Fixed 60 tall; red is Fill(max 120) tall, blue is Fill tall. Both must stretch to 60, not vanish.",
      "txt_099": "Square image. Left: Fit x Fit with max width 96 -> 96x96. Middle: Fill(max 140) x Fit -> 140x140. Right: Fixed 80 wide x Fit(max 40) tall -> 80x40 (height clamped). Last row (control): Fit(min 120) image and Fixed 120 image must be the same size; orange takes the rest.",
      "txt_104": "This paragraph is Fill width with a maximum of 220dp, so it wraps at 220 no matter how wide the screen is.",
      "txt_183": "Blue is Fill(min 96, max 96): exactly 96 wide regardless of siblings. Orange and green split the rest equally.",
      "txt_098": "7. Images keep aspect ratio while clamped",
      "txt_107": "short",
      "txt_108": "8. Text with min/max widths",
      "txt_109": "Top: Fill(max 220) text wraps at 220 and is start-aligned in the row. Bottom: Fit(min 200) around short text -> 200-wide yellow box.",
      "txt_116": "9. Margins extend min/max",
      "txt_117": "Blue is Fill(max 100) with 16dp margin on every side: its painted box is 100 wide but it occupies 132 in the row, and is 48+32 tall. Orange fills the rest.",
      "txt_123": "10. Overrides add a cap per screen size",
      "txt_124": "Blue is Fill with an override: compact -> max 80, medium -> max 200, expanded -> no cap. Rotate / use a tablet to compare. Orange fills the rest.",
      "txt_131": "11. Nested Fit(min) does not steal a sibling's Fill space",
      "txt_132": "Purple is a Fit(min 160) row holding one 32dp block; orange is a Fill sibling. Purple is exactly 160 and orange takes the rest.",
      "txt_147": "12. Minimum larger than the parent wins",
      "txt_148": "Purple row is Fixed 200 wide. Red is Fill(min 260): it overflows the purple bounds by 60. Navy row is Fixed 40 tall; green is Fill(min 64) tall and overflows vertically. Rows 1-2 have rounded corners (may clip the overflow); rows 3-4 are square with no background so the 260 / 64 must be fully visible. If 1-2 look clamped but 3-4 overflow, that is clipping, not clamping.",
      "txt_166": "13. SPACE_* with capped Fill children",
      "txt_167": "Three Fill(max 60) blocks in a Fill row. They stay 60 wide; the leftover is distributed as SPACE_BETWEEN / SPACE_AROUND / SPACE_EVENLY.",
      "txt_174": "14. Fit(min) height with centered content",
      "txt_175": "Purple column is Fit(min 120) tall with a 24dp block and CENTER distribution: 120 tall, block vertically centered.",
      "txt_182": "15. Fill(min == max) behaves like Fixed",
      "txt_186": "centered",
      "txt_189": "16. Root-level: Fit(min/max) width stack",
      "txt_190": "Purple column is Fit(min 200, max 280) wide, centered. Its text child is short, so the column is exactly 200 wide.",
      "txt_203": "17. Mins exceeding the row: overflow with fixed spacing",
      "txt_204": "Row 1 (control): two Fill(min 120) blocks fit on any phone -> equal halves, no overflow. Row 2: two Fill(min 220) inside a Fixed 300 row -> overflows the purple by 148, purple stays 300. Row 3: two Fill(min 220) in a Fill row can't fit on a phone: the pair overflows the canvas equally on both sides. The gray ruler at the top of the sheet must NOT get wider than the screen: an unsatisfiable min must not grow its Fill ancestors or the root.",
      "txt_213": "18. Hidden sibling does not shift constraints",
      "txt_214": "Blue Fill(max 60), an invisible Fill block, then orange Fill. Blue must still be 60 and orange must take everything else.",
      "txt_231": "19. Padding lives INSIDE the constraint (width)",
      "txt_232": "Each pair: a padded stack above a Fixed reference of the same width. Right edges must line up. Fixed 200 + 20 padding = 200 outer; Fill(max 160) + 20 padding = 160 outer; Fit(min 200) + 20 padding = 200 outer. If the padded box is 40 wider than its reference, padding is being applied outside the constraint.",
      "txt_243": "20. Padding lives INSIDE the constraint (height)",
      "txt_244": "Left: Fit(min 80) tall with 20 padding around a 16dp block. Middle: Fixed 80 tall with 20 padding. Right: Fixed 80 reference. All three must be exactly 80 tall.",
      "txt_262": "21. Overflow policy: clipped vs visible",
      "txt_263": "Same content as 4 (Fit(max 160) holding 192 + spacing of blocks, CENTER). Row 1: square corners, no background. Row 2: rounded corners + background. Row 3: rounded + border. All three must render the overflow the same way on every platform; decide whether that is clipped or visible, but it must not differ per row or per platform.",
      "txt_283": "22. Preview-harness replica (Fixed 240 x 72, no padding, no shape)",
      "txt_284": "These mirror the iOS/Android StackPreview harness so a preview snapshot and this paywall can be compared 1:1. Spacing 8. Row 1: Fill(max 60) | Fill | Fill(min 140) -> 60 / 24 / 140. Row 2: Fit(min 160) | Fit(min 160) -> 328 in a 240 box, overflow anchored START. Row 3: Fill(min 100, max 100) | Fill -> 100 / 132.",
      "txt_289": "max60",
      "txt_290": "fill",
      "txt_291": "min140",
      "txt_293": "This text is Fit with min 120 and max 200 so it must wrap at 200 wide.",
      "txt_296": "ok",
      "txt_299": "23. Text children carry min/max too",
      "txt_300": "Row 1: three TEXT children Fill(max 60) | Fill | Fill(min 140) -> same 60 / rest / 140 split as section 1, text must stay visible (not collapse to 0). Row 2: Fit(min 120, max 200) text with a long string -> wraps at 200, box is 200 wide. Row 3: Fit(min 120) text 'ok' -> 120-wide yellow box, text start-aligned.",
      "txt_313": "24. Fill child inside a Fit(min) parent",
      "txt_314": "Purple row is Fit(min 200) with 8 padding holding one Fill block: purple is exactly 200, yellow is 184 (200 - 16). Orange sibling takes the rest. Second row: same but the Fill child has max 100 -> purple still 200, yellow 100 anchored START.",
      "txt_322": "Fill text, no min or max",
      "txt_329": "25. Legacy control: no min/max anywhere",
      "txt_330": "Nothing in this section uses min or max. It must look identical with the feature flag ON and OFF, and identical to the main branch. Row 1: Fill | Fill | Fixed 48 -> two equal halves and a 48 block. Row 2: Fill TEXT | Fill stack -> text gets half the row and stays visible (ui-js regression check). Row 3: Fit row hugging two 32 blocks, centered.",
      "txt_335": "Min / Max size constraints test sheet v2",
      "txt_336": "Each section states the expected result. Sizes in dp. Light gray canvases mark the demo stack bounds. The navy ruler below is Fill width: it must end at the screen edge. If it runs off-screen, a min propagated to the root (see 17).",
      "txt_337": "root width",
      "txt_339": "root width"
    }
  },
  "config": {},
  "created_at": "2026-08-17T20:23:37Z",
  "default_locale": "en_US",
  "exit_offers": {},
  "generated_by": "dashboard",
  "haptic_feedback_enabled": false,
  "localized_strings": {},
  "localized_strings_by_tier": {},
  "metadata": {},
  "name": "Min/Max size constraints test sheet v2",
  "offering_id": "ofrng199b327ae0",
  "params": [],
  "play_store_product_change_mode": {},
  "rc_public_id": "pw1c55d9f1c6cf42a8",
  "revision": 28,
  "source": "workflow",
  "state_declarations": {},
  "template_name": "components",
  "updated_at": "2026-09-09T15:36:13Z"
}
"""#

#endif

// swiftlint:enable line_length
