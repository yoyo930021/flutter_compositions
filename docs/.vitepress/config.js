import { defineConfig } from 'vitepress'

export default defineConfig({
  // Top-level site configuration
  base: '/flutter_compositions/',
  lang: 'en-US',
  socialLinks: [
    { icon: 'github', link: 'https://github.com/yoyo930021/flutter_compositions' }
  ],

  // Internationalization configuration
  locales: {
    // Chinese (Simplified) version
    root: {
      label: '繁體中文',
      lang: 'zh-TW',
      title: "Flutter Compositions",
      description: "為 Flutter 打造的響應式組合 API。",

      themeConfig: {
        nav: [
          { text: '指南', link: '/guide/getting-started' },
          { text: '深入原理', link: '/internals/architecture' },
          { text: '測試', link: '/testing/testing-guide' },
          { text: 'Lint 規則', link: '/lints/README' },
        ],
        sidebar: {
          '/guide/': [
            {
              text: '指南',
              items: [
                { text: '快速上手', link: '/guide/getting-started' },
                { text: '深入理解組合式 API', link: '/guide/what-is-a-composition' },
                { text: '響應式基礎', link: '/guide/reactivity-fundamentals' },
                { text: '進階響應式技巧', link: '/guide/reactivity' },
                { text: '從 StatefulWidget 遷移', link: '/guide/from-stateful-widget' },
                { text: '內建 Composables', link: '/guide/built-in-composables' },
                { text: '建立您自己的 Composables', link: '/guide/creating-composables' },
                { text: '非同步操作', link: '/guide/async-operations' },
                { text: '依賴注入', link: '/guide/dependency-injection' },
                { text: '與 flutter_hooks 比較', link: '/guide/flutter-hooks-comparison' },
                { text: '與 Vue Composition API 比較', link: '/guide/vue-comparison' },
                { text: '最佳實務', link: '/guide/best-practices' },
                { text: '為什麼選擇本框架', link: '/guide/why-choose' },
              ]
            }
          ],
          '/testing/': [
            {
              text: '測試',
              items: [
                { text: '測試指南', link: '/testing/testing-guide' },
              ]
            }
          ],
          '/lints/': [
            {
              text: 'Lint 規則',
              items: [
                { text: '使用說明', link: '/lints/README' },
                { text: '快速索引', link: '/lints/index' },
                { text: '規則一覽', link: '/lints/rules' },
              ]
            }
          ],
          '/internals/': [
            {
              text: '深入原理',
              items: [
                { text: '架構概觀', link: '/internals/architecture' },
                { text: '響應式系統詳解', link: '/internals/reactivity-in-depth' },
                { text: '技術深入解析', link: '/internals/technical-deep-dive' },
                { text: '效能考量', link: '/internals/performance' },
                { text: '設計理念與取捨', link: '/internals/design-trade-offs' },
              ]
            }
          ]
        },
        footer: {
          message: 'Released under the MIT License.',
          copyright: 'Copyright © 2024-present yoyo930021'
        },
        docFooter: {
          prev: '上一頁',
          next: '下一頁'
        }
      }
    },

    // English version
    en: {
      label: 'English',
      lang: 'en-US',
      title: "Flutter Compositions",
      description: "A Vue-like Composition API for Flutter.",

      themeConfig: {
        nav: [
          { text: 'Guide', link: '/en/guide/getting-started' },
          { text: 'Internals', link: '/en/internals/architecture' },
          { text: 'Testing', link: '/en/testing/testing-guide' },
          { text: 'Lints', link: '/en/lints/README' },
        ],
        sidebar: {
          '/en/guide/': [
            {
              text: 'Guide',
              items: [
                { text: 'Getting Started', link: '/en/guide/getting-started' },
                { text: 'Understanding the API', link: '/en/guide/what-is-a-composition' },
                { text: 'Reactivity Fundamentals', link: '/en/guide/reactivity-fundamentals' },
                { text: 'Advanced Reactivity', link: '/en/guide/reactivity' },
                { text: 'From StatefulWidget', link: '/en/guide/from-stateful-widget' },
                { text: 'Built-in Composables', link: '/en/guide/built-in-composables' },
                { text: 'Creating Your Own', link: '/en/guide/creating-composables' },
                { text: 'Async Operations', link: '/en/guide/async-operations' },
                { text: 'Dependency Injection', link: '/en/guide/dependency-injection' },
                { text: 'Flutter vs flutter_hooks', link: '/en/guide/flutter-hooks-comparison' },
                { text: 'Flutter vs Vue Composition API', link: '/en/guide/vue-comparison' },
                { text: 'Best Practices', link: '/en/guide/best-practices' },
                { text: 'Why This Framework', link: '/en/guide/why-choose' },
              ]
            }
          ],
          '/en/testing/': [
            {
              text: 'Testing',
              items: [
                { text: 'Testing Guide', link: '/en/testing/testing-guide' },
              ]
            }
          ],
          '/en/lints/': [
            {
              text: 'Lints',
              items: [
                { text: 'Getting Started', link: '/en/lints/README' },
                { text: 'Quick Reference', link: '/en/lints/index' },
                { text: 'Rule Catalogue', link: '/en/lints/rules' },
              ]
            }
          ],
          '/en/internals/': [
            {
              text: 'Internals',
              items: [
                { text: 'Architecture Overview', link: '/en/internals/architecture' },
                { text: 'Reactivity in Depth', link: '/en/internals/reactivity-in-depth' },
                { text: 'Technical Deep Dive', link: '/en/internals/technical-deep-dive' },
                { text: 'Design Trade-offs', link: '/en/internals/design-trade-offs' },
              ]
            }
          ]
        },
        footer: {
          message: 'Released under the MIT License.',
          copyright: 'Copyright © 2024-present yoyo930021'
        },
        docFooter: {
          prev: 'Previous page',
          next: 'Next page'
        }
      }
    }
  }
})
