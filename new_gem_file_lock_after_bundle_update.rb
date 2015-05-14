PATH
  remote: .
  specs:
    tripod (0.9.1)
      activemodel (~> 3.2)
      dalli (~> 2.6)
      equivalent-xml
      guid
      json-ld (~> 0.9.1)
      rdf (~> 1.0)
      rdf-json
      rdf-rdfxml
      rdf-turtle
      rest-client

GEM
  remote: https://rubygems.org/
  specs:
    activemodel (3.2.16)
      activesupport (= 3.2.16)
      builder (~> 3.0.0)
    activesupport (3.2.16)
      i18n (~> 0.6, >= 0.6.4)
      multi_json (~> 1.0)
    addressable (2.3.5)
    backports (3.5.0)
    builder (3.0.4)
    crack (0.4.2)
      safe_yaml (~> 1.0.0)
    dalli (2.7.0)
    diff-lcs (1.2.5)
    ebnf (0.3.5)
      rdf
      sxp
    equivalent-xml (0.4.0)
      nokogiri (>= 1.4.3)
    guid (0.1.1)
    haml (4.0.5)
      tilt
    htmlentities (4.3.1)
    i18n (0.6.9)
    json (1.8.1)
    json-ld (0.9.1)
      backports
      json (>= 1.7.5)
      rdf (>= 1.0)
    mime-types (2.1)
    mini_portile (0.5.2)
    multi_json (1.8.4)
    nokogiri (1.6.1)
      mini_portile (~> 0.5.0)
    rdf (1.1.2.1)
    rdf-json (1.1.0)
      rdf (>= 1.1.0)
    rdf-rdfa (1.1.2)
      haml (>= 4.0)
      htmlentities (>= 4.3.1)
      rdf (>= 1.1.0)
      rdf-xsd (>= 1.1)
    rdf-rdfxml (1.1.0)
      rdf (>= 1.1)
      rdf-rdfa (>= 1.1)
      rdf-xsd (>= 1.1)
    rdf-turtle (1.1.2)
      ebnf (>= 0.3.5)
      rdf (>= 1.1.1.1)
    rdf-xsd (1.1.0)
      rdf (>= 1.1)
    rest-client (1.6.7)
      mime-types (>= 1.16)
    rspec (2.14.1)
      rspec-core (~> 2.14.0)
      rspec-expectations (~> 2.14.0)
      rspec-mocks (~> 2.14.0)
    rspec-core (2.14.7)
    rspec-expectations (2.14.5)
      diff-lcs (>= 1.1.3, < 2.0)
    rspec-mocks (2.14.5)
    safe_yaml (1.0.1)
    sxp (0.1.5)
    tilt (2.0.0)
    webmock (1.17.2)
      addressable (>= 2.2.7)
      crack (>= 0.3.2)

PLATFORMS
  ruby

DEPENDENCIES
  rspec (~> 2.14)
  tripod!
  webmock
