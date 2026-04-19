# case-shift.nvim

Small local plugin for converting the identifier under the cursor between:

- `camelCase`
- `snake_case`
- `PascalCase`
- `kebab-case`
- `CONSTANT_CASE`
- `__dunder_case__`
- `_private_case`

Commands:

- `:CaseShift`
- `:CaseShift camelCase`
- `:CaseShift snake_case`
- `:CaseShift PascalCase`
- `:CaseShift kebab-case`
- `:CaseShift CONSTANT_CASE`
- `:CaseShift __dunder_case__`
- `:CaseShift _private_case`
- `:CaseShiftPicker`

`:CaseShift` and `:CaseShiftPicker` open a Telescope picker that shows the
target convention alongside the converted preview before applying it.

Alias commands:

- `:ToCamelCase`
- `:ToSnakeCase`
- `:ToPascalCase`
- `:ToKebabCase`
- `:ToConstantCase`
- `:ToDunderCase`
- `:ToPrivateCase`
