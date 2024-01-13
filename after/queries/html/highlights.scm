;; extends 
; use THIS https://tree-sitter.github.io/tree-sitter/using-parsers#pattern-matching-with-queries for reference

; hide start tags of notes
(element (_)@start_tags
(#match? @start_tags "<[/]?card*>") (#set! conceal ""))
