/**
 * Puffin Validators - Prolog Implementation
 *
 * This module provides validation predicates for Puffin entities.
 * Translated from src/shared/validators.js
 */

:- module(validators, [
    validate_project/2,
    validate_prompt/2,
    validate_gui_element/2,
    validate_branch/2,
    sanitize_string/2,
    is_valid_file_path/1
]).

%% validate_project(+Project, -Result)
%
% Validates a project configuration.
% Project is expected to be a dict with keys: name, description, assumptions
% Result is either valid or invalid(Errors) where Errors is a list
validate_project(Project, Result) :-
    (   var(Project)
    ->  Result = invalid(['Project is required'])
    ;   findall(Error, project_error(Project, Error), Errors),
        (   Errors = []
        ->  Result = valid
        ;   Result = invalid(Errors)
        )
    ).

% Helper predicates for project validation
project_error(Project, 'Project name is required') :-
    (   \+ get_dict(name, Project, _)
    ;   get_dict(name, Project, Name),
        (   (atom(Name) -> atom_length(Name, 0) ; string_length(Name, 0))
        )
    ).

project_error(Project, 'Project name must be 100 characters or less') :-
    get_dict(name, Project, Name),
    (atom(Name) -> atom_length(Name, Len) ; string_length(Name, Len)),
    Len > 100.

project_error(Project, 'Project description is required') :-
    (   \+ get_dict(description, Project, _)
    ;   get_dict(description, Project, Desc),
        \+ (atom(Desc) ; string(Desc))
    ).

project_error(Project, 'Assumptions must be an array') :-
    get_dict(assumptions, Project, Assumptions),
    \+ is_list(Assumptions).

%% validate_prompt(+Prompt, -Result)
%
% Validates a prompt object.
% Prompt should have content and branchId
validate_prompt(Prompt, Result) :-
    (   var(Prompt)
    ->  Result = invalid(['Prompt is required'])
    ;   findall(Error, prompt_error(Prompt, Error), Errors),
        (   Errors = []
        ->  Result = valid
        ;   Result = invalid(Errors)
        )
    ).

% Helper predicates for prompt validation
prompt_error(Prompt, 'Prompt content is required') :-
    (   \+ get_dict(content, Prompt, _)
    ;   get_dict(content, Prompt, Content),
        (   (atom(Content) -> atom_length(Content, 0) ; string_length(Content, 0))
        )
    ).

prompt_error(Prompt, 'Branch ID is required') :-
    (   \+ get_dict(branchId, Prompt, _)
    ;   get_dict(branchId, Prompt, BranchId),
        \+ (atom(BranchId) ; string(BranchId))
    ).

%% validate_gui_element(+Element, -Result)
%
% Validates a GUI element.
% Element should have type and properties
validate_gui_element(Element, Result) :-
    (   var(Element)
    ->  Result = invalid(['Element is required'])
    ;   findall(Error, gui_element_error(Element, Error), Errors),
        (   Errors = []
        ->  Result = valid
        ;   Result = invalid(Errors)
        )
    ).

% Valid GUI element types
valid_gui_type(container).
valid_gui_type(text).
valid_gui_type(input).
valid_gui_type(button).
valid_gui_type(image).
valid_gui_type(list).
valid_gui_type(form).
valid_gui_type(nav).
valid_gui_type(card).
valid_gui_type(modal).

% Helper predicates for GUI element validation
gui_element_error(Element, Error) :-
    (   \+ get_dict(type, Element, _)
    ->  Error = 'Element type is required'
    ;   get_dict(type, Element, Type),
        \+ valid_gui_type(Type),
        findall(T, valid_gui_type(T), Types),
        atomic_list_concat(['Element type must be one of: '|Types], ', ', Error)
    ).

gui_element_error(Element, 'Element properties are required') :-
    (   \+ get_dict(properties, Element, _)
    ;   get_dict(properties, Element, Props),
        \+ is_dict(Props)
    ).

%% validate_branch(+Branch, -Result)
%
% Validates a branch configuration.
% Branch should have id, name, and optionally prompts
validate_branch(Branch, Result) :-
    (   var(Branch)
    ->  Result = invalid(['Branch is required'])
    ;   findall(Error, branch_error(Branch, Error), Errors),
        (   Errors = []
        ->  Result = valid
        ;   Result = invalid(Errors)
        )
    ).

% Helper predicates for branch validation
branch_error(Branch, 'Branch ID is required') :-
    (   \+ get_dict(id, Branch, _)
    ;   get_dict(id, Branch, Id),
        \+ (atom(Id) ; string(Id))
    ).

branch_error(Branch, 'Branch name is required') :-
    (   \+ get_dict(name, Branch, _)
    ;   get_dict(name, Branch, Name),
        (   \+ (atom(Name) ; string(Name))
        ;   (atom(Name) -> atom_length(Name, 0) ; string_length(Name, 0))
        )
    ).

branch_error(Branch, 'Branch prompts must be an array') :-
    get_dict(prompts, Branch, Prompts),
    \+ is_list(Prompts).

%% sanitize_string(+Input, -Output)
%
% Sanitizes a string for safe HTML display.
% Replaces special characters with HTML entities
sanitize_string(Input, Output) :-
    (   (atom(Input) ; string(Input))
    ->  (atom(Input) -> atom_string(Input, InputStr) ; InputStr = Input),
        replace_chars(InputStr, Output)
    ;   Output = ''
    ).

replace_chars(Input, Output) :-
    string_chars(Input, Chars),
    maplist(sanitize_char, Chars, SanitizedChars),
    string_chars(Output, SanitizedChars).

sanitize_char('&', '&amp;') :- !.
sanitize_char('<', '&lt;') :- !.
sanitize_char('>', '&gt;') :- !.
sanitize_char('"', '&quot;') :- !.
sanitize_char('\'', '&#039;') :- !.
sanitize_char(C, C).

%% is_valid_file_path(+Path)
%
% Validates a file path for security.
% Prevents directory traversal and checks for valid characters
is_valid_file_path(Path) :-
    (atom(Path) -> atom_string(Path, PathStr) ; PathStr = Path),
    string(PathStr),
    \+ sub_string(PathStr, _, _, _, '..'),
    string_chars(PathStr, Chars),
    maplist(valid_path_char, Chars).

% Valid characters for file paths
valid_path_char(C) :- char_type(C, alnum), !.
valid_path_char('_') :- !.
valid_path_char('-') :- !.
valid_path_char('.') :- !.
valid_path_char('/') :- !.
valid_path_char('\\').
