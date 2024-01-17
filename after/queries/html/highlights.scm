;; extends 
; use THIS https://tree-sitter.github.io/tree-sitter/using-parsers#pattern-matching-with-queries for reference

; hide start tags of notes
((comment)@start_tags
(#eq? @start_tags "<!-- card -->") (#set! conceal "🎓"))

((comment)@start_tags
(#match? @start_tags r"<!-- card*-->") (#set! conceal "🎓"))

((comment)@tags
(#eq? @tags "<!-- back -->") (#set! conceal "↻"))
