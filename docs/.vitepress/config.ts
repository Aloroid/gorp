import { defineConfig } from "vitepress"

// https://vitepress.dev/reference/site-config
export default defineConfig({
    lang: 'en-US',
    title: "gorp",
    titleTemplate: ":title - A ECR debugging and profiling library",

    description: "A ECR debugging and profiling library",
    base: "/gorp/",
    head: [["link", { rel: "icon", href: "/favicon.svg" }]],
    ignoreDeadLinks: true,

    themeConfig: {
        logo: "/logo.svg",
        siteTitle: "",

        // https://vitepress.dev/reference/default-theme-config
        nav: [
            { text: "Home", link: "/" },
            { text: "Tutorials", link: "/tut/crashcourse" },
            { text: "API", link: "/api/gorp"},
        ],

        outline: "deep",

        sidebar: {
            "/api/": [
                {
                    text: "API",
                    items: [
                        { text: "gorp", link: "/api/gorp" },
                        { text: "Scheduler", link: "/api/scheduler" },
                        { text: "Style", link: "/api/style" },
                    ]
                }
            ],

            "/tut/": [
                {
                    text: "Tutorials",
                    items: [
                        { text: "Crash Course", link: "/tut/crashcourse" },
                        { text: "Scheduler", link: "/tut/scheduler" },
                        
                    ]
                }
            ],
        },

        socialLinks: [
             { icon: "github", link: "https://github.com/aloroid/gorp" }
        ],

        footer: {
            message: "Released under MIT"
        }
    },

})