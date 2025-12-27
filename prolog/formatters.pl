/**
 * Puffin Formatters - Prolog Implementation
 *
 * This module provides formatting predicates for Puffin.
 * Translated from src/shared/formatters.js
 */

:- module(formatters, [
    generate_id/1,
    format_date/2,
    format_relative_time/2,
    truncate/3,
    format_file_size/2,
    gui_to_description/2,
    build_project_context/2,
    flatten_prompt_tree/2
]).

:- use_module(library(uuid)).
:- use_module(library(dicts)).

%% generate_id(-Id)
%
% Generates a UUID v4 identifier
generate_id(Id) :-
    uuid(Uuid),
    atom_string(Uuid, Id).

%% format_date(+Timestamp, -Formatted)
%
% Formats a timestamp to a readable date string
% Timestamp should be a Unix timestamp (seconds since epoch)
format_date(Timestamp, Formatted) :-
    stamp_date_time(Timestamp, DateTime, local),
    format_time(string(Formatted), '%b %d, %Y %H:%M', DateTime).

%% format_relative_time(+Timestamp, -Formatted)
%
% Formats a timestamp as relative time (e.g., "2 hours ago")
format_relative_time(Timestamp, Formatted) :-
    get_time(Now),
    Diff is Now - Timestamp,
    Seconds is floor(Diff),
    (   Seconds < 60
    ->  Formatted = 'just now'
    ;   Minutes is Seconds // 60,
        (   Minutes < 60
        ->  format(string(Formatted), '~wm ago', [Minutes])
        ;   Hours is Minutes // 60,
            (   Hours < 24
            ->  format(string(Formatted), '~wh ago', [Hours])
            ;   Days is Hours // 24,
                (   Days < 7
                ->  format(string(Formatted), '~wd ago', [Days])
                ;   format_date(Timestamp, Formatted)
                )
            )
        )
    ).

%% truncate(+Text, +MaxLength, -Truncated)
%
% Truncates text with ellipsis if it exceeds max length
truncate(Text, MaxLength, Truncated) :-
    (   Text = ''
    ->  Truncated = ''
    ;   string_length(Text, Len),
        (   Len =< MaxLength
        ->  Truncated = Text
        ;   TruncLen is MaxLength - 3,
            sub_string(Text, 0, TruncLen, _, Prefix),
            string_concat(Prefix, '...', Truncated)
        )
    ).

%% format_file_size(+Bytes, -Formatted)
%
% Formats file size in bytes to human-readable format
format_file_size(0, '0 B') :- !.
format_file_size(Bytes, Formatted) :-
    K = 1024,
    Sizes = ['B', 'KB', 'MB', 'GB'],
    I is floor(log(Bytes) / log(K)),
    nth0(I, Sizes, Unit),
    Value is Bytes / (K ** I),
    format(string(Formatted), '~2f ~w', [Value, Unit]).

%% gui_to_description(+Elements, -Description)
%
% Converts GUI designer elements to Claude-readable description
gui_to_description([], 'No UI elements defined.') :- !.
gui_to_description(Elements, Description) :-
    string_concat('## UI Layout Description\n\n', '', Header),
    maplist(describe_element(0), Elements, Descriptions),
    atomic_list_concat([Header|Descriptions], '\n', Description).

% Helper to describe a single element
describe_element(Indent, Element, Description) :-
    get_dict(type, Element, Type),
    get_dict(properties, Element, Props),
    format(string(Prefix), '~*c', [Indent * 2, 0' ]),
    string_chars(Type, [First|Rest]),
    upcase_atom(First, FirstUpper),
    string_chars(TypeCap, [FirstUpper|Rest]),
    format(string(Base), '~w- **~w**', [Prefix, TypeCap]),
    (   get_dict(label, Props, Label)
    ->  format(string(WithLabel), '~w: "~w"', [Base, Label])
    ;   WithLabel = Base
    ),
    (   get_dict(placeholder, Props, Placeholder)
    ->  format(string(WithPlaceholder), '~w (placeholder: "~w")', [WithLabel, Placeholder])
    ;   WithPlaceholder = WithLabel
    ),
    format_dimensions(Props, DimStr),
    string_concat(WithPlaceholder, DimStr, Description).

format_dimensions(Props, DimStr) :-
    findall(Dim, (
        (   get_dict(width, Props, W),
            format(string(Dim), 'width: ~wpx', [W])
        ;   get_dict(height, Props, H),
            format(string(Dim), 'height: ~wpx', [H])
        )
    ), Dims),
    (   Dims = []
    ->  DimStr = ''
    ;   atomic_list_concat(Dims, ', ', DimsStr),
        format(string(DimStr), ' [~w]', [DimsStr])
    ).

%% build_project_context(+Project, -Context)
%
% Builds prompt context from project configuration
build_project_context(Project, Context) :-
    Lines = ['# Project Context\n'],
    add_section(description, Project, Lines, Lines1),
    add_section(assumptions, Project, Lines1, Lines2),
    add_section(technical_architecture, Project, Lines2, Lines3),
    add_section(data_model, Project, Lines3, Lines4),
    add_section(options, Project, Lines4, Lines5),
    atomic_list_concat(Lines5, '\n', Context).

% Helper to add sections
add_section(description, Project, In, Out) :-
    (   get_dict(description, Project, Desc),
        Desc \= ''
    ->  append(In, ['## Description', Desc, ''], Out)
    ;   Out = In
    ).

add_section(assumptions, Project, In, Out) :-
    (   get_dict(assumptions, Project, Assumptions),
        Assumptions \= []
    ->  maplist(format_assumption, Assumptions, FormattedAssumptions),
        append(In, ['## Assumptions'|FormattedAssumptions], Temp),
        append(Temp, [''], Out)
    ;   Out = In
    ).

add_section(technical_architecture, Project, In, Out) :-
    (   get_dict(technical_architecture, Project, Arch),
        Arch \= ''
    ->  append(In, ['## Technical Architecture', Arch, ''], Out)
    ;   Out = In
    ).

add_section(data_model, Project, In, Out) :-
    (   get_dict(data_model, Project, Model),
        Model \= ''
    ->  append(In, ['## Data Model', Model, ''], Out)
    ;   Out = In
    ).

add_section(options, Project, In, Out) :-
    (   get_dict(options, Project, Opts)
    ->  format_options(Opts, OptLines),
        append(In, ['## Coding Preferences'|OptLines], Temp),
        append(Temp, [''], Out)
    ;   Out = In
    ).

format_assumption(A, Formatted) :-
    format(string(Formatted), '- ~w', [A]).

format_options(Opts, Lines) :-
    findall(Line, (
        (   get_dict(programming_style, Opts, Style),
            format(string(Line), '- Programming Style: ~w', [Style])
        ;   get_dict(testing_approach, Opts, Test),
            format(string(Line), '- Testing Approach: ~w', [Test])
        ;   get_dict(documentation_level, Opts, Doc),
            format(string(Line), '- Documentation Level: ~w', [Doc])
        ;   get_dict(error_handling, Opts, Error),
            format(string(Line), '- Error Handling: ~w', [Error])
        ;   get_dict(code_style, Opts, CodeStyle),
            format_code_style(CodeStyle, Line)
        )
    ), Lines).

format_code_style(CodeStyle, Line) :-
    (   get_dict(naming, CodeStyle, Naming)
    ->  format(string(Line), '- Naming Convention: ~w', [Naming])
    ;   get_dict(comments, CodeStyle, Comments),
        format(string(Line), '- Comment Style: ~w', [Comments])
    ).

%% flatten_prompt_tree(+Branch, -FlatTree)
%
% Converts prompt history tree to flat array with depth
% Shows newest prompts first while maintaining parent-child hierarchy
flatten_prompt_tree(Branch, FlatTree) :-
    get_dict(prompts, Branch, Prompts),
    traverse_prompts(Prompts, 0, null, FlatTree).

traverse_prompts(Prompts, Depth, ParentId, Result) :-
    findall(P, (
        member(P, Prompts),
        get_dict(parent_id, P, ParentId)
    ), Children),
    sort_prompts_by_timestamp(Children, SortedChildren),
    maplist(process_prompt(Prompts, Depth), SortedChildren, Results),
    flatten(Results, Result).

process_prompt(AllPrompts, Depth, Prompt, [Enhanced|ChildResults]) :-
    Enhanced = Prompt.put(depth, Depth),
    get_dict(id, Prompt, Id),
    NextDepth is Depth + 1,
    traverse_prompts(AllPrompts, NextDepth, Id, ChildResults).

sort_prompts_by_timestamp(Prompts, Sorted) :-
    map_list_to_pairs(get_timestamp, Prompts, Pairs),
    keysort(Pairs, SortedPairs),
    pairs_values(SortedPairs, Sorted).

get_timestamp(Prompt, Timestamp) :-
    (   get_dict(timestamp, Prompt, T)
    ->  Timestamp is -T  % Negative for descending sort
    ;   Timestamp = 0
    ).
