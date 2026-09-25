import { loadEnv, defineConfig } from "@medusajs/framework/utils"

loadEnv(process.env.NODE_ENV || "development", process.cwd())

module.exports = defineConfig({
  projectConfig: {
    databaseUrl: process.env.DATABASE_URL,
    redisUrl: process.env.REDIS_URL,

    databaseDriverOptions: {
      ssl: false,
      sslmode: "disable",
    },

    http: {
      storeCors: process.env.STORE_CORS!,
      adminCors: process.env.ADMIN_CORS!,
      authCors: process.env.AUTH_CORS!,
      jwtSecret: process.env.JWT_SECRET,
      cookieSecret: process.env.COOKIE_SECRET,
    },
  },

  admin: {
    vite: (config) => {
      return {
        ...config,
        server: {
          ...config.server,
          host: "0.0.0.0",

          // 仅适合你现在 NAS 局域网开发
          allowedHosts: true,

          hmr: {
            port: 5173,
            clientPort: 5173,
          },
        },
      }
    },
  },
})
