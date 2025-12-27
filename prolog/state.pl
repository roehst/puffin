/**
 * Puffin State Management - Prolog Implementation
 *
 * This module provides state management predicates for Puffin.
 * Implements the SAM (State-Action-Model) pattern in Prolog.
 * Translated from src/renderer/sam/model.js
 */

:- module(state, [
    initial_model/1,
    apply_proposal/3,
    compute_state/2,
    transition/3
]).

:- use_module(library(dicts)).

%% initial_model(-Model)
%
% Returns the initial model state for the application
initial_model(Model) :-
    Model = model{
        % Application state
        initialized: false,
        app_error: null,
        
        % Project info
        project_path: null,
        project_name: null,
        
        % Config state
        config: config{
            name: '',
            description: '',
            assumptions: [],
            technical_architecture: '',
            data_model: '',
            default_model: sonnet,
            options: options{
                programming_style: 'HYBRID',
                testing_approach: 'TDD',
                documentation_level: 'STANDARD',
                error_handling: 'EXCEPTIONS',
                code_style: code_style{
                    naming: 'CAMEL',
                    comments: 'JSDoc'
                }
            },
            ux_style: ux_style{
                baseline_css: '',
                alignment: left,
                font_family: 'system-ui, -apple-system, sans-serif',
                font_size: '16px',
                color_palette: color_palette{
                    primary: '#6c63ff',
                    secondary: '#16213e',
                    accent: '#48bb78',
                    background: '#ffffff',
                    text: '#1a1a2e',
                    error: '#f56565'
                }
            }
        },
        
        % Prompt state
        current_prompt: prompt{
            content: '',
            branch_id: null
        },
        pending_prompt_id: null,
        streaming_response: '',
        
        % History state
        history: history{
            branches: branches{
                specifications: branch{id: specifications, name: 'Specifications', prompts: []},
                architecture: branch{id: architecture, name: 'Architecture', prompts: []},
                ui: branch{id: ui, name: 'UI', prompts: []},
                backend: branch{id: backend, name: 'Backend', prompts: []},
                deployment: branch{id: deployment, name: 'Deployment', prompts: []},
                tmp: branch{id: tmp, name: 'Tmp', prompts: []}
            },
            active_branch: specifications,
            active_prompt_id: null,
            expanded_threads: threads{},
            thread_search_query: ''
        },
        
        % GUI Designer state
        gui_elements: [],
        selected_gui_element: null,
        
        % Architecture state
        architecture: architecture{
            content: '',
            updated_at: null
        },
        
        % User stories state
        user_stories: [],
        
        % Sprint state
        active_sprint: null
    }.

%% apply_proposal(+Model, +Proposal, -NewModel)
%
% Applies a proposal to the model, returning a new model state.
% This is the "acceptor" part of SAM pattern.
apply_proposal(Model, Proposal, NewModel) :-
    proposal_type(Proposal, Type),
    apply_typed_proposal(Type, Model, Proposal, NewModel).

% Determine proposal type
proposal_type(Proposal, Type) :-
    (   get_dict(action, Proposal, Type)
    ->  true
    ;   Type = unknown
    ).

% Apply different types of proposals
apply_typed_proposal(init, Model, Proposal, NewModel) :-
    get_dict(project_path, Proposal, Path),
    get_dict(project_name, Proposal, Name),
    NewModel = Model.put([
        initialized: true,
        project_path: Path,
        project_name: Name
    ]).

apply_typed_proposal(update_config, Model, Proposal, NewModel) :-
    get_dict(config, Proposal, ConfigUpdate),
    get_dict(config, Model, OldConfig),
    merge_dicts(OldConfig, ConfigUpdate, NewConfig),
    NewModel = Model.put(config, NewConfig).

apply_typed_proposal(submit_prompt, Model, Proposal, NewModel) :-
    get_dict(prompt, Proposal, Prompt),
    get_dict(branch_id, Proposal, BranchId),
    NewModel = Model.put([
        current_prompt: Prompt,
        pending_prompt_id: BranchId
    ]).

apply_typed_proposal(stream_response, Model, Proposal, NewModel) :-
    get_dict(chunk, Proposal, Chunk),
    get_dict(streaming_response, Model, Current),
    string_concat(Current, Chunk, Updated),
    NewModel = Model.put(streaming_response, Updated).

apply_typed_proposal(complete_response, Model, _Proposal, NewModel) :-
    NewModel = Model.put([
        streaming_response: '',
        pending_prompt_id: null
    ]).

apply_typed_proposal(set_error, Model, Proposal, NewModel) :-
    get_dict(error, Proposal, Error),
    NewModel = Model.put(app_error, Error).

apply_typed_proposal(clear_error, Model, _Proposal, NewModel) :-
    NewModel = Model.put(app_error, null).

apply_typed_proposal(unknown, Model, _Proposal, Model).

% Helper to merge dicts
merge_dicts(Base, Updates, Result) :-
    dict_pairs(Updates, Tag, UpdatePairs),
    dict_pairs(Base, Tag, BasePairs),
    merge_pairs(BasePairs, UpdatePairs, MergedPairs),
    dict_pairs(Result, Tag, MergedPairs).

merge_pairs([], Updates, Updates).
merge_pairs([K-V|Rest], Updates, [K-NewV|MergedRest]) :-
    (   member(K-NewV, Updates)
    ->  select(K-NewV, Updates, RemainingUpdates)
    ;   NewV = V, RemainingUpdates = Updates
    ),
    merge_pairs(Rest, RemainingUpdates, MergedRest).

%% compute_state(+Model, -State)
%
% Computes the application state from the model.
% This is the "state function" part of SAM pattern.
compute_state(Model, State) :-
    get_dict(initialized, Model, Initialized),
    (   Initialized = false
    ->  AppState = uninitialized
    ;   get_dict(app_error, Model, Error),
        (   Error \= null
        ->  AppState = error
        ;   get_dict(pending_prompt_id, Model, PendingId),
            (   PendingId \= null
            ->  AppState = streaming
            ;   AppState = ready
            )
        )
    ),
    State = state{
        app_state: AppState,
        model: Model
    }.

%% transition(+CurrentState, +Event, -NextState)
%
% Defines state transitions based on events.
% This implements FSM (Finite State Machine) logic.
transition(uninitialized, init, initializing).
transition(initializing, success, ready).
transition(initializing, error, error).
transition(ready, submit_prompt, streaming).
transition(streaming, complete, ready).
transition(streaming, error, error).
transition(error, clear_error, ready).
transition(State, _, State).  % Default: stay in same state
