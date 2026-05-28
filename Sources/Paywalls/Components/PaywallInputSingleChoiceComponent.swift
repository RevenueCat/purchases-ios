// swiftlint:disable missing_docs nesting
import Foundation

@_spi(Internal) public extension PaywallComponent {

    final class InputSingleChoiceComponent: PaywallComponentBase {

        let type: ComponentType
        public let fieldId: String
        public let required: Bool
        public let stack: StackComponent
        public let overrides: ComponentOverrides<PartialInputSingleChoiceComponent>?

        public init(
            fieldId: String,
            required: Bool = false,
            stack: StackComponent,
            overrides: ComponentOverrides<PartialInputSingleChoiceComponent>? = nil
        ) {
            self.type = .inputSingleChoice
            self.fieldId = fieldId
            self.required = required
            self.stack = stack
            self.overrides = overrides
        }

        private enum CodingKeys: String, CodingKey {
            case type
            case fieldId
            case required
            case stack
            case overrides
        }

        public required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.type = try container.decode(ComponentType.self, forKey: .type)
            self.fieldId = try container.decode(String.self, forKey: .fieldId)
            self.required = try container.decodeIfPresent(Bool.self, forKey: .required) ?? false
            self.stack = try container.decode(StackComponent.self, forKey: .stack)
            self.overrides = try container.decodeIfPresent(
                ComponentOverrides<PartialInputSingleChoiceComponent>.self,
                forKey: .overrides
            )
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(type, forKey: .type)
            try container.encode(fieldId, forKey: .fieldId)
            try container.encode(required, forKey: .required)
            try container.encode(stack, forKey: .stack)
            try container.encodeIfPresent(overrides, forKey: .overrides)
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(fieldId)
            hasher.combine(required)
            hasher.combine(stack)
            hasher.combine(overrides)
        }

        public static func == (lhs: InputSingleChoiceComponent, rhs: InputSingleChoiceComponent) -> Bool {
            lhs.type == rhs.type &&
            lhs.fieldId == rhs.fieldId &&
            lhs.required == rhs.required &&
            lhs.stack == rhs.stack &&
            lhs.overrides == rhs.overrides
        }

    }

    final class PartialInputSingleChoiceComponent: PaywallPartialComponent {

        public let fieldId: String?
        public let required: Bool?

        public init(fieldId: String? = nil, required: Bool? = nil) {
            self.fieldId = fieldId
            self.required = required
        }

        private enum CodingKeys: String, CodingKey {
            case fieldId
            case required
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(fieldId)
            hasher.combine(required)
        }

        public static func == (
            lhs: PartialInputSingleChoiceComponent,
            rhs: PartialInputSingleChoiceComponent
        ) -> Bool {
            lhs.fieldId == rhs.fieldId && lhs.required == rhs.required
        }

    }

    // MARK: -

    final class InputOptionComponent: PaywallComponentBase {

        let type: ComponentType
        public let optionId: String
        public let optionValue: String
        public let stack: StackComponent
        /// Maps trigger-type strings (e.g. "on_press") to action IDs.
        /// Decoded for completeness; the backend serialises these into WorkflowStep.stepTriggers so
        /// iOS calls workflowTriggerAction(optionId) at runtime and never reads this dict directly.
        public let triggers: [String: String]?
        public let overrides: ComponentOverrides<PartialInputOptionComponent>?

        public init(
            optionId: String,
            optionValue: String,
            stack: StackComponent,
            triggers: [String: String]? = nil,
            overrides: ComponentOverrides<PartialInputOptionComponent>? = nil
        ) {
            self.type = .inputOption
            self.optionId = optionId
            self.optionValue = optionValue
            self.stack = stack
            self.triggers = triggers
            self.overrides = overrides
        }

        private enum CodingKeys: String, CodingKey {
            case type
            case optionId
            case optionValue
            case stack
            case triggers
            case overrides
        }

        public required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.type = try container.decode(ComponentType.self, forKey: .type)
            self.optionId = try container.decode(String.self, forKey: .optionId)
            self.optionValue = try container.decode(String.self, forKey: .optionValue)
            self.stack = try container.decode(StackComponent.self, forKey: .stack)
            self.triggers = try container.decodeIfPresent([String: String].self, forKey: .triggers)
            self.overrides = try container.decodeIfPresent(
                ComponentOverrides<PartialInputOptionComponent>.self,
                forKey: .overrides
            )
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(type, forKey: .type)
            try container.encode(optionId, forKey: .optionId)
            try container.encode(optionValue, forKey: .optionValue)
            try container.encode(stack, forKey: .stack)
            try container.encodeIfPresent(triggers, forKey: .triggers)
            try container.encodeIfPresent(overrides, forKey: .overrides)
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(optionId)
            hasher.combine(optionValue)
            hasher.combine(stack)
            hasher.combine(triggers)
            hasher.combine(overrides)
        }

        public static func == (lhs: InputOptionComponent, rhs: InputOptionComponent) -> Bool {
            lhs.type == rhs.type &&
            lhs.optionId == rhs.optionId &&
            lhs.optionValue == rhs.optionValue &&
            lhs.stack == rhs.stack &&
            lhs.triggers == rhs.triggers &&
            lhs.overrides == rhs.overrides
        }

    }

    final class PartialInputOptionComponent: PaywallPartialComponent {

        public let optionId: String?
        public let optionValue: String?
        public let triggers: [String: String]?

        public init(
            optionId: String? = nil,
            optionValue: String? = nil,
            triggers: [String: String]? = nil
        ) {
            self.optionId = optionId
            self.optionValue = optionValue
            self.triggers = triggers
        }

        private enum CodingKeys: String, CodingKey {
            case optionId
            case optionValue
            case triggers
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(optionId)
            hasher.combine(optionValue)
            hasher.combine(triggers)
        }

        public static func == (
            lhs: PartialInputOptionComponent,
            rhs: PartialInputOptionComponent
        ) -> Bool {
            lhs.optionId == rhs.optionId &&
            lhs.optionValue == rhs.optionValue &&
            lhs.triggers == rhs.triggers
        }

    }

}
