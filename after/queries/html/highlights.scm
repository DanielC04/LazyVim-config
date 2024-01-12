;; extends 
; use THIS https://tree-sitter.github.io/tree-sitter/using-parsers#pattern-matching-with-queries for reference

; hide start tags of notes
(element (start_tag)@start_tags
(#eq? @start_tags "<card>") (#set! conceal ""))
; same for end-tags
(element (end_tag)@end_tags
(#eq? @end_tags "</card>") (#set! conceal ""))

; hide other keywords of notes
(element (self_closing_tag)@self_closing_tags
(#any-of? @self_closing_tags "<clozen/>" "<basic/>\n" "<basic/>" "<delete/>" "<frozen/>") (#set! conceal ""))


