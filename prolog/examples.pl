#!/usr/bin/env swipl

/**
 * Puffin Prolog Interactive Examples
 * 
 * Run this file with: swipl -s prolog/examples.pl
 * Then try the example queries listed below
 */

:- use_module('puffin.pl').

% Display welcome message
:- initialization(welcome).

welcome :-
    nl,
    write('🦜 Welcome to Puffin Prolog Examples!'), nl,
    nl,
    write('Try these queries:'), nl,
    nl,
    write('== Validation Examples =='), nl,
    write('?- validate_project(project{name: ''Test'', description: ''A test'', assumptions: []}, R).'), nl,
    write('?- validate_prompt(prompt{content: ''Build a feature'', branchId: ''backend''}, R).'), nl,
    nl,
    write('== Model Examples =='), nl,
    write('?- claude_model(opus, Name, Desc, Tier).'), nl,
    write('?- all_models(Models).'), nl,
    write('?- default_model(M).'), nl,
    nl,
    write('== State Management Examples =='), nl,
    write('?- initial_model(M), get_dict(initialized, M, Init).'), nl,
    write('?- transition(uninitialized, init, Next).'), nl,
    nl,
    write('== Formatter Examples =='), nl,
    write('?- generate_id(Id).'), nl,
    write('?- truncate(''This is a long text'', 10, T).'), nl,
    write('?- format_file_size(2048, S).'), nl,
    nl,
    write('== Advanced Examples =='), nl,
    write('?- example_validation_workflow.'), nl,
    write('?- example_state_transition.'), nl,
    write('?- example_model_selection.'), nl,
    nl,
    write('Type ?- <query>. to execute a query'), nl,
    write('Type halt. to exit'), nl,
    nl.

%% example_validation_workflow
%
% Demonstrates a complete validation workflow
example_validation_workflow :-
    nl,
    write('=== Validation Workflow Example ==='), nl,
    nl,
    % Validate a project
    Project = project{
        name: 'E-Commerce Platform',
        description: 'A modern e-commerce solution',
        assumptions: ['Cloud infrastructure', 'Mobile-first design']
    },
    write('1. Validating project: '), write(Project), nl,
    validate_project(Project, ProjectResult),
    write('   Result: '), write(ProjectResult), nl,
    nl,
    % Validate a prompt
    Prompt = prompt{
        content: 'Implement shopping cart functionality',
        branchId: 'backend'
    },
    write('2. Validating prompt: '), write(Prompt), nl,
    validate_prompt(Prompt, PromptResult),
    write('   Result: '), write(PromptResult), nl,
    nl,
    % Validate a GUI element
    Element = element{
        type: button,
        properties: properties{
            label: 'Add to Cart',
            width: 200,
            height: 40
        }
    },
    write('3. Validating GUI element: '), write(Element), nl,
    validate_gui_element(Element, ElementResult),
    write('   Result: '), write(ElementResult), nl,
    nl.

%% example_state_transition
%
% Demonstrates state transitions in the SAM pattern
example_state_transition :-
    nl,
    write('=== State Transition Example ==='), nl,
    nl,
    % Get initial model
    write('1. Initial model state:'), nl,
    initial_model(M1),
    get_dict(initialized, M1, Init1),
    write('   Initialized: '), write(Init1), nl,
    nl,
    % Apply initialization proposal
    write('2. Applying init proposal...'), nl,
    InitProposal = proposal{
        action: init,
        project_path: '/home/user/myproject',
        project_name: 'My Project'
    },
    apply_proposal(M1, InitProposal, M2),
    get_dict(initialized, M2, Init2),
    get_dict(project_name, M2, ProjectName),
    write('   Initialized: '), write(Init2), nl,
    write('   Project Name: '), write(ProjectName), nl,
    nl,
    % Compute state
    write('3. Computing application state...'), nl,
    compute_state(M2, State),
    get_dict(app_state, State, AppState),
    write('   App State: '), write(AppState), nl,
    nl,
    % Show transition
    write('4. State transitions:'), nl,
    transition(uninitialized, init, S1),
    write('   uninitialized --init--> '), write(S1), nl,
    transition(S1, success, S2),
    write('   '), write(S1), write(' --success--> '), write(S2), nl,
    nl.

%% example_model_selection
%
% Demonstrates model queries and selection
example_model_selection :-
    nl,
    write('=== Model Selection Example ==='), nl,
    nl,
    % List all models
    write('1. Available models:'), nl,
    all_models(Models),
    forall(member(ModelId, Models), (
        claude_model(ModelId, Name, Desc, Tier),
        format('   • ~w (~w) - ~w~n', [Name, Tier, Desc])
    )),
    nl,
    % Get default model
    default_model(Default),
    write('2. Default model: '), write(Default), nl,
    nl,
    % Get fast model
    fast_model(Fast),
    write('3. Fast model (for quick ops): '), write(Fast), nl,
    nl,
    % Model recommendation logic
    write('4. Model recommendation:'), nl,
    write('   For complex tasks: '),
    claude_model(opus, OpusName, _, _),
    write(OpusName), nl,
    write('   For balanced performance: '),
    claude_model(sonnet, SonnetName, _, _),
    write(SonnetName), nl,
    write('   For quick operations: '),
    claude_model(haiku, HaikuName, _, _),
    write(HaikuName), nl,
    nl.

%% example_advanced_validation
%
% Demonstrates advanced validation patterns
example_advanced_validation :-
    nl,
    write('=== Advanced Validation Examples ==='), nl,
    nl,
    % Test multiple projects
    write('1. Batch validation:'), nl,
    Projects = [
        project{name: 'Valid1', description: 'First valid project', assumptions: []},
        project{description: 'Invalid - no name'},
        project{name: 'Valid2', description: 'Second valid project', assumptions: ['Assumption 1']}
    ],
    forall(member(P, Projects), (
        validate_project(P, R),
        (R = valid -> write('   ✓ ') ; write('   ✗ ')),
        (get_dict(name, P, N) -> write(N) ; write('(unnamed)')),
        nl
    )),
    nl,
    % Security validation
    write('2. Security validation:'), nl,
    Paths = [
        'safe/path/file.txt',
        '../../../etc/passwd',
        'normal/file.js',
        'path/with/../../traversal'
    ],
    forall(member(Path, Paths), (
        (is_valid_file_path(Path) -> write('   ✓ ') ; write('   ✗ ')),
        write(Path), nl
    )),
    nl.
