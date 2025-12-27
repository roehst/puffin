/**
 * Puffin - Main Prolog Module
 *
 * This is the main entry point for the Puffin Prolog backend.
 * It provides a unified interface to all Puffin modules.
 */

:- module(puffin, [
    % Re-export validators
    validate_project/2,
    validate_prompt/2,
    validate_gui_element/2,
    validate_branch/2,
    sanitize_string/2,
    is_valid_file_path/1,
    
    % Re-export models
    claude_model/4,
    default_model/1,
    fast_model/1,
    all_models/1,
    model_by_id/2,
    
    % Re-export state management
    initial_model/1,
    apply_proposal/3,
    compute_state/2,
    transition/3,
    
    % Re-export formatters
    generate_id/1,
    format_date/2,
    format_relative_time/2,
    truncate/3,
    format_file_size/2,
    gui_to_description/2,
    build_project_context/2,
    flatten_prompt_tree/2,
    
    % Main interface predicates
    puffin_version/1,
    puffin_info/0
]).

% Load all submodules
:- use_module('validators.pl').
:- use_module('models.pl').
:- use_module('state.pl').
:- use_module('formatters.pl').

% Re-export predicates from submodules
:- reexport('validators.pl').
:- reexport('models.pl').
:- reexport('state.pl').
:- reexport('formatters.pl').

%% puffin_version(-Version)
%
% Returns the current Prolog implementation version
puffin_version('0.1.0-prolog').

%% puffin_info
%
% Prints information about the Puffin Prolog implementation
puffin_info :-
    puffin_version(Version),
    format('~n=== Puffin Prolog Implementation ===~n', []),
    format('Version: ~w~n', [Version]),
    format('~nLoaded Modules:~n', []),
    format('  - validators: Project, prompt, GUI, and branch validation~n', []),
    format('  - models: Claude model definitions and queries~n', []),
    format('  - state: SAM pattern state management~n', []),
    format('  - formatters: Formatting utilities and converters~n', []),
    format('~nUsage:~n', []),
    format('  ?- validate_project(Project, Result).~n', []),
    format('  ?- claude_model(opus, Name, Desc, Tier).~n', []),
    format('  ?- initial_model(Model).~n', []),
    format('  ?- generate_id(Id).~n', []),
    format('~n', []).
