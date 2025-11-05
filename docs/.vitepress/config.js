import { defineConfig } from 'vitepress'

export default defineConfig({
  // Top-level site configuration
  base: '/flutter_compositions/',
  socialLinks: [
    { icon: 'github', link: 'https://github.com/yoyo930021/flutter_compositions' }
  ],

  rewrites: {
    'en/:rest*': ':rest*'
  },

  // Internationalization configuration
  locales: {
    // English version
    root: {
      label: 'English',
      lang: 'en-US',
      title: "Flutter Compositions",
      description: "A Vue-like Composition API for Flutter.",

      themeConfig: {
        nav: [
          { text: 'Guide', link: '/guide/getting-started' },
          { text: 'Internals', link: '/internals/architecture' },
          { text: 'Testing', link: '/testing/testing-guide' },
          { text: 'Lints', link: '/lints/README' },
          {
            text: 'API Reference',
            link: 'https://pub.dev/documentation/flutter_compositions/latest/'
          },
          {
            text: 'GitHub',
            link: 'https://github.com/yoyo930021/flutter_compositions'
          }
        ],
        sidebar: {
          '/guide/': [
            {
              text: 'Guide',
              items: [
                { text: 'Getting Started', link: '/guide/getting-started' },
                { text: 'Understanding the API', link: '/guide/what-is-a-composition' },
                { text: 'Reactivity Fundamentals', link: '/guide/reactivity-fundamentals' },
                { text: 'Advanced Reactivity', link: '/guide/reactivity' },
                { text: 'From StatefulWidget', link: '/guide/from-stateful-widget' },
                { text: 'Built-in Composables', link: '/guide/built-in-composables' },
                { text: 'Creating Your Own', link: '/guide/creating-composables' },
                { text: 'Async Operations', link: '/guide/async-operations' },
                { text: 'Dependency Injection', link: '/guide/dependency-injection' },
                { text: 'Flutter vs flutter_hooks', link: '/guide/flutter-hooks-comparison' },
                { text: 'Flutter vs Vue Composition API', link: '/guide/vue-comparison' },
                { text: 'Best Practices', link: '/guide/best-practices' },
                { text: 'Why This Framework', link: '/guide/why-choose' },
              ]
            }
          ],
          '/testing/': [
            {
              text: 'Testing',
              items: [
                { text: 'Testing Guide', link: '/testing/testing-guide' },
              ]
            }
          ],
          '/lints/': [
            {
              text: 'Lints',
              items: [
                { text: 'Getting Started', link: '/lints/index' },
                { text: 'Rule Catalogue', link: '/lints/rules' },
              ]
            }
          ],
          '/internals/': [
            {
              text: 'Internals',
              items: [
                { text: 'Architecture Overview', link: '/internals/architecture' },
                { text: 'Reactivity in Depth', link: '/internals/reactivity-in-depth' },
                { text: 'Technical Deep Dive', link: '/internals/technical-deep-dive' },
                { text: 'Design Trade-offs', link: '/internals/design-trade-offs' },
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
    },
    // Chinese version
    zh: {
      label: '繁體中文',
      lang: 'zh-TW',
      title: "Flutter Compositions",
      description: "為 Flutter 打造的響應式組合 API。",

      themeConfig: {
        nav: [
          { text: '指南', link: '/zh/guide/getting-started' },
          { text: '深入原理', link: '/zh/internals/architecture' },
          { text: '測試', link: '/zh/testing/testing-guide' },
          { text: 'Lint 規則', link: '/zh/lints/README' },
          {
            text: 'API 參考',
            link: 'https://pub.dev/documentation/flutter_compositions/latest/'
          },
          {
            text: 'GitHub',
            link: 'https://github.com/yoyo930021/flutter_compositions'
          }
        ],
        sidebar: {
          '/zh/guide/': [
            {
              text: '指南',
              items: [
                { text: '快速上手', link: '/zh/guide/getting-started' },
                { text: '深入理解組合式 API', link: '/zh/guide/what-is-a-composition' },
                { text: '響應式基礎', link: '/zh/guide/reactivity-fundamentals' },
                { text: '進階響應式技巧', link: '/zh/guide/reactivity' },
                { text: '從 StatefulWidget 遷移', link: '/zh/guide/from-stateful-widget' },
                { text: '內建 Composables', link: '/zh/guide/built-in-composables' },
                { text: '建立您自己的 Composables', link: '/zh/guide/creating-composables' },
                { text: '非同步操作', link: '/zh/guide/async-operations' },
                { text: '依賴注入', link: '/zh/guide/dependency-injection' },
                { text: '與 flutter_hooks 比較', link: '/zh/guide/flutter-hooks-comparison' },
                { text: '與 Vue Composition API 比較', link: '/zh/guide/vue-comparison' },
                { text: '最佳實務', link: '/zh/guide/best-practices' },
                { text: '為什麼選擇本框架', link: '/zh/guide/why-choose' },
              ]
            }
          ],
          '/zh/testing/': [
            {
              text: '測試',
              items: [
                { text: '測試指南', link: '/zh/testing/testing-guide' },
              ]
            }
          ],
          '/zh/lints/': [
            {
              text: 'Lint 規則',
              items: [
                { text: '使用說明', link: '/zh/lints/index' },
                { text: '規則一覽', link: '/zh/lints/rules' },
              ]
            }
          ],
          '/zh/internals/': [
            {
              text: '深入原理',
              items: [
                { text: '架構概觀', link: '/zh/internals/architecture' },
                { text: '響應式系統詳解', link: '/zh/internals/reactivity-in-depth' },
                { text: '技術深入解析', link: '/zh/internals/technical-deep-dive' },
                { text: '效能考量', link: '/zh/internals/performance' },
                { text: '設計理念與取捨', link: '/zh/internals/design-trade-offs' },
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
    }
  }
})
