/// Prepares the configuration of a template for the deploy request.
enum TemplateConfig {
    /// Gives each variable of each service its default as its `value`, as the Railway CLI
    /// does before a deploy. All other fields stay as Railway gave them, also the fields
    /// that Topway does not know. A variable with no default that is not optional needs a
    /// value from the user, and Topway has no screen for that, so it throws.
    static func filled(_ config: JSONValue) throws -> JSONValue {
        guard case .object(var root) = config, case .object(var services)? = root["services"]
        else { return config }

        for (serviceId, serviceValue) in services {
            guard case .object(var service) = serviceValue,
                case .object(var variables)? = service["variables"]
            else { continue }

            for (name, variableValue) in variables {
                guard case .object(var variable) = variableValue else { continue }
                if case .string(let defaultValue)? = variable["defaultValue"], !defaultValue.isEmpty
                {
                    variable["value"] = .string(defaultValue)
                    variables[name] = .object(variable)
                } else if variable["isOptional"] != .bool(true) {
                    throw TemplateConfigProblem.missingVariable(name)
                }
            }
            service["variables"] = .object(variables)
            services[serviceId] = .object(service)
        }
        root["services"] = .object(services)
        return .object(root)
    }
}
