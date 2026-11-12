import Foundation

/// The data that a new `SampleDataSource` starts with.
extension SampleDataSource {
    static let seedProjects: [Project] = [
        project("storefront", services: ["web", "api", "worker", "postgres", "redis"]),
        project("analytics", services: ["dashboard", "ingest", "postgres"]),
        project("docs", services: ["site"]),
    ]

    /// The deployments of each service, newest first, with their age in minutes.
    static let seedDeployments:
        [(environmentId: String, serviceId: String, deployments: [(status: String, age: Int)])] = [
            (
                "storefront-production", "storefront-web",
                [("SUCCESS", 120), ("REMOVED", 1_440), ("FAILED", 1_500)]
            ),
            (
                "storefront-production", "storefront-api",
                [("BUILDING", 2), ("SUCCESS", 180), ("REMOVED", 2_880)]
            ),
            ("storefront-production", "storefront-worker", [("CRASHED", 20), ("SUCCESS", 1_440)]),
            ("storefront-production", "storefront-postgres", [("SUCCESS", 10_080)]),
            ("storefront-production", "storefront-redis", [("SUCCESS", 10_080)]),
            ("storefront-staging", "storefront-web", [("DEPLOYING", 1), ("SUCCESS", 300)]),
            (
                "storefront-staging", "storefront-api",
                [("QUEUED", 1), ("SKIPPED", 60), ("SUCCESS", 400)]
            ),
            ("storefront-staging", "storefront-worker", [("WAITING", 5), ("SUCCESS", 600)]),
            ("storefront-staging", "storefront-postgres", [("SUCCESS", 10_080)]),
            ("analytics-production", "analytics-dashboard", [("SUCCESS", 240), ("FAILED", 300)]),
            ("analytics-production", "analytics-ingest", [("SUCCESS", 30)]),
            ("analytics-production", "analytics-postgres", [("SUCCESS", 20_160)]),
            ("analytics-staging", "analytics-dashboard", [("SLEEPING", 4_320)]),
            ("docs-production", "docs-site", [("SUCCESS", 60), ("REMOVED", 2_000)]),
        ]

    /// The variables of each environment and service. Railway references stay plain text.
    /// A sealed variable has the value `nil`, as in the answer of Railway.
    static let seedVariables: [String: [String: String?]] = [
        "storefront-production/storefront-web": [
            "API_URL": "https://${{ api.RAILWAY_PUBLIC_DOMAIN }}",
            "NODE_ENV": "production",
            "PORT": "3000",
        ],
        "storefront-production/storefront-api": [
            "DATABASE_URL": "${{ postgres.DATABASE_URL }}",
            "REDIS_URL": "${{ redis.REDIS_URL }}",
            "LOG_LEVEL": "${{ shared.LOG_LEVEL }}",
            "PORT": "8080",
            "STRIPE_SECRET_KEY": nil,
        ],
        "storefront-production/storefront-worker": [
            "DATABASE_URL": "${{ postgres.DATABASE_URL }}",
            // The project has no billing service, so this reference has a missing target.
            "BILLING_URL": "${{ billing.API_URL }}",
            "QUEUE_CONCURRENCY": "4",
        ],
        "storefront-production/storefront-postgres": [
            "DATABASE_URL":
                "postgresql://postgres:sample-password@postgres.railway.internal:5432/railway",
            "PGUSER": "postgres",
            "POSTGRES_DB": "railway",
        ],
        "storefront-production/storefront-redis": [
            "REDIS_URL": "redis://default:sample-password@redis.railway.internal:6379"
        ],
        "storefront-staging/storefront-api": [
            "DATABASE_URL": "${{ postgres.DATABASE_URL }}",
            "LOG_LEVEL": "debug",
            "PORT": "8080",
        ],
        "analytics-production/analytics-ingest": [
            "DATABASE_URL": "${{ postgres.DATABASE_URL }}",
            "BATCH_SIZE": "500",
        ],
        "docs-production/docs-site": ["SITE_URL": "https://docs.example.com"],
    ]

    /// The shared variables of each environment.
    static let seedSharedVariables: [String: [String: String]] = [
        "storefront-production": ["LOG_LEVEL": "info"]
    ]

    /// The build log of each sample deployment, as severity and message.
    static let seedBuildLogs: [(severity: String, message: String)] = [
        ("info", "Using Nixpacks"),
        ("info", "setup │ nodejs_22, npm-10_x"),
        ("info", "install │ npm ci"),
        ("warn", "npm warn deprecated inflight@1.0.6: This module is not supported"),
        ("info", "build │ npm run build"),
        ("info", "start │ npm run start"),
        ("info", "Build time: 42.10 seconds"),
    ]

    /// The deploy log lines that show when the stream starts.
    static let seedDeployLogs: [(severity: String, message: String)] = [
        ("info", "Starting server on port 3000"),
        ("info", "Connected to postgres.railway.internal:5432"),
        ("info", "GET /health 200 2ms"),
        ("warn", "Slow query: 820ms on orders"),
        ("info", "GET /api/products 200 34ms"),
        ("error", "Payment webhook failed: timeout after 10s"),
    ]

    /// The deploy log lines that arrive later, one for each tick, in a loop.
    static let seedLiveLogs: [(severity: String, message: String)] = [
        ("info", "GET /health 200 1ms"),
        ("info", "GET /api/cart 200 12ms"),
        ("warn", "Cache miss rate above 40%"),
        ("error", "Request to inventory failed: connection reset"),
    ]

    /// Makes a project with a production and a staging environment. The IDs come from the names.
    private static func project(_ name: String, services: [String]) -> Project {
        Project(
            id: name,
            name: name,
            services: ServiceConnection(
                edges: services.map { ServiceEdge(node: Service(id: "\(name)-\($0)", name: $0)) }),
            environments: EnvironmentConnection(
                edges: ["production", "staging"].map {
                    EnvironmentEdge(node: RailwayEnvironment(id: "\(name)-\($0)", name: $0))
                })
        )
    }
}
