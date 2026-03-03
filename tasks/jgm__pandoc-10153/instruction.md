Pandoc’s JATS writer does not currently export author contribution roles using the CRediT taxonomy. When users provide CRediT role information in document metadata, the generated JATS should include one or more <role> elements under each author’s <contrib> in <contrib-group>, but currently this information is ignored and no <role> elements are emitted.

Pandoc should support specifying author roles in metadata (e.g., in YAML) and then exporting conformant JATS role elements. Metadata can include an author list where each author may have a roles field containing a list of role dictionaries. Each role dictionary must accept:

- credit: the CRediT role identifier (required), e.g. "software", "conceptualization", "writing-original-draft".
- credit-name: the primary English label for the role (optional). If omitted, Pandoc should look up the appropriate CRediT label from the credit identifier.
- name: a display name override (optional), used for internationalization; if provided it should be used as the element text content (and typically should also be reflected in the vocab-term attribute).
- degree: an optional contribution degree; when present it must be exported as the JATS attribute degree-contribution and should support exactly these values: "Lead", "Supporting", or "Equal".

When converting to JATS (e.g. pandoc -s -t jats), each author role entry should produce a <role> element inside that author’s <contrib contrib-type="author">. The <role> element must include CRediT vocabulary attributes matching the JATS expectation:

- vocab="credit"
- vocab-identifier="https://credit.niso.org/"
- vocab-term-identifier="https://credit.niso.org/contributor-roles/<credit>/" (where <credit> is the role identifier)
- vocab-term set to the chosen label (credit-name or name, depending on what is used)
- degree-contribution="<degree>" only when degree is provided

The text content of <role> should be the chosen label (credit-name if provided or looked up; otherwise name if provided). Multiple roles for the same author should result in multiple <role> sibling elements.

Example expected behavior: given metadata like

author:
  - name: Max Mustermann
    roles:
      - credit: software
        degree: Lead

JATS output should include a role like:

<role vocab="credit" degree-contribution="Lead"
      vocab-identifier="https://credit.niso.org/"
      vocab-term-identifier="https://credit.niso.org/contributor-roles/software/"
      vocab-term="Software">Software</role>

If the role includes name: Programas, then the role element’s text (and vocab-term) should use "Programas" rather than the default English label.

This support should be added in a way that works with normal JATS generation (including when authors also have affiliations, ORCID IDs, etc.), without breaking existing JATS output for documents that do not specify roles.