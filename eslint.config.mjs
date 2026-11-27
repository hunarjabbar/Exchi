import tseslint from 'typescript-eslint';
export default [
 {ignores:['**/node_modules/**','**/dist/**','**/.next/**','**/next-env.d.ts','packages/database/generated/**']},
 {files:['apps/**/*.ts','apps/**/*.tsx','packages/**/*.ts','packages/**/*.tsx'],languageOptions:{parser:tseslint.parser,parserOptions:{ecmaFeatures:{jsx:true},sourceType:'module'}},plugins:{'@typescript-eslint':tseslint.plugin},rules:{'@typescript-eslint/no-explicit-any':'error','no-debugger':'error','no-duplicate-imports':'error','no-unreachable':'error','no-unsafe-finally':'error','no-constant-binary-expression':'error'}}
];
