/**
 * Puffin Prolog Tests
 *
 * Test suite for the Prolog implementation of Puffin
 */

:- use_module('puffin.pl').

% Test validators
test_validators :-
    write('Testing validators...'), nl,
    
    % Test valid project
    Project1 = project{name: 'Test Project', description: 'A test project', assumptions: []},
    validate_project(Project1, Result1),
    (Result1 = valid -> write('  ✓ Valid project passes') ; write('  ✗ Valid project fails')), nl,
    
    % Test invalid project (no name)
    Project2 = project{description: 'Test'},
    validate_project(Project2, Result2),
    (Result2 = invalid(_) -> write('  ✓ Invalid project detected') ; write('  ✗ Invalid project not detected')), nl,
    
    % Test valid prompt
    Prompt1 = prompt{content: 'Test prompt', branchId: 'specifications'},
    validate_prompt(Prompt1, Result3),
    (Result3 = valid -> write('  ✓ Valid prompt passes') ; write('  ✗ Valid prompt fails')), nl,
    
    % Test file path validation
    (is_valid_file_path('valid/path/file.txt') -> write('  ✓ Valid file path') ; write('  ✗ Valid file path fails')), nl,
    (\+ is_valid_file_path('../etc/passwd') -> write('  ✓ Invalid file path rejected') ; write('  ✗ Invalid file path not rejected')), nl,
    
    write('Validators tests completed!'), nl, nl.

% Test models
test_models :-
    write('Testing models...'), nl,
    
    % Test model queries
    (claude_model(opus, Name, _, _) -> 
        format('  ✓ Found model: ~w~n', [Name]) ; 
        write('  ✗ Model not found'), nl),
    
    default_model(Default),
    format('  ✓ Default model: ~w~n', [Default]),
    
    fast_model(Fast),
    format('  ✓ Fast model: ~w~n', [Fast]),
    
    all_models(Models),
    length(Models, Count),
    format('  ✓ Total models: ~w~n', [Count]),
    
    write('Models tests completed!'), nl, nl.

% Test state management
test_state :-
    write('Testing state management...'), nl,
    
    % Test initial model
    initial_model(Model),
    (get_dict(initialized, Model, false) -> 
        write('  ✓ Initial model created') ; 
        write('  ✗ Initial model failed')), nl,
    
    % Test applying a proposal
    Proposal = proposal{action: init, project_path: '/test/path', project_name: 'Test'},
    apply_proposal(Model, Proposal, NewModel),
    (get_dict(initialized, NewModel, true) -> 
        write('  ✓ Proposal applied successfully') ; 
        write('  ✗ Proposal application failed')), nl,
    
    % Test state computation
    compute_state(Model, State),
    get_dict(app_state, State, AppState),
    format('  ✓ Computed state: ~w~n', [AppState]),
    
    % Test transitions
    transition(uninitialized, init, NextState),
    format('  ✓ Transition: uninitialized -> ~w~n', [NextState]),
    
    write('State management tests completed!'), nl, nl.

% Test formatters
test_formatters :-
    write('Testing formatters...'), nl,
    
    % Test ID generation
    generate_id(Id),
    string_length(Id, Len),
    (Len > 0 -> write('  ✓ ID generated') ; write('  ✗ ID generation failed')), nl,
    
    % Test truncation
    truncate('This is a very long text that should be truncated', 20, Truncated),
    (sub_string(Truncated, _, _, _, '...') -> 
        write('  ✓ Text truncated correctly') ; 
        write('  ✗ Text truncation failed')), nl,
    
    % Test file size formatting
    format_file_size(1024, Size),
    format('  ✓ File size formatted: ~w~n', [Size]),
    
    write('Formatters tests completed!'), nl, nl.

% Main test runner
run_all_tests :-
    write(''), nl,
    write('=== Puffin Prolog Test Suite ==='), nl,
    write(''), nl,
    test_validators,
    test_models,
    test_state,
    test_formatters,
    write('=== All tests completed! ==='), nl,
    write(''), nl.

% Run tests when loaded
:- initialization(run_all_tests).
