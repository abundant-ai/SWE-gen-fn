`refmt` formats record destructuring that uses a local open with incorrect indentation. When destructuring a record using `Module.{ ... }` on the left-hand side of a `let` binding, the formatter currently prints the record fields with excessive indentation and misaligned closing `}`/`,` compared to standard record formatting.

For example, formatting the following code:

```reason
let EnterpriseContactForm.{
      personFirstNameField,
      personLastNameField,
      personEmailField,
      companyNameField,
      countryField,
      companySizeField,
      contactReasonField,
      submitFormState,
      onSubmit,
    } = formData;
```

should produce:

```reason
let EnterpriseContactForm.{
  personFirstNameField,
  personLastNameField,
  personEmailField,
  companyNameField,
  countryField,
  companySizeField,
  contactReasonField,
  submitFormState,
  onSubmit,
} = formData;
```

Expected behavior: when a local open prefix like `EnterpriseContactForm.` is used with record destructuring (`.{ ... }`), the formatter should indent the record fields by the normal record indentation level (e.g., `shift` spaces) and align the closing brace `}` consistently with the `let ...` line, matching how other record literals/patterns are formatted.

Actual behavior: fields are printed as if they were nested more deeply than they are, keeping a large leading indentation from the original input (or otherwise producing an over-indented layout), and the closing brace/comma alignment does not match the standard style.

Fix `refmt` so that this formatting is stable and consistent regardless of the original input indentation, including under typical auto-format settings (e.g., `wrap=80` and `shift=2`).