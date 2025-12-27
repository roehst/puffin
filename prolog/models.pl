/**
 * Available Claude models for Puffin - Prolog Implementation
 *
 * This module defines the available Claude models and their properties.
 * Translated from src/shared/models.js
 */

:- module(models, [
    claude_model/4,
    default_model/1,
    fast_model/1,
    all_models/1,
    model_by_id/2
]).

%% claude_model(?Id, ?Name, ?Description, ?Tier)
%
% Defines available Claude models.
% Id: Model identifier
% Name: Human-readable name
% Description: Model description
% Tier: Model tier (premium, standard, fast)
claude_model(opus, 'Claude Opus', 'Most capable, best for complex tasks', premium).
claude_model(sonnet, 'Claude Sonnet', 'Balanced performance and speed', standard).
claude_model(haiku, 'Claude Haiku', 'Fast and lightweight', fast).

%% default_model(-Model)
%
% Returns the default model for new projects
default_model(opus).

%% fast_model(-Model)
%
% Returns the fast model for quick operations (title generation, etc.)
fast_model(haiku).

%% all_models(-Models)
%
% Returns a list of all available model IDs
all_models(Models) :-
    findall(Id, claude_model(Id, _, _, _), Models).

%% model_by_id(+Id, -Model)
%
% Retrieves model information by ID.
% Model is returned as a dict with keys: id, name, description, tier
model_by_id(Id, Model) :-
    claude_model(Id, Name, Description, Tier),
    Model = model{id: Id, name: Name, description: Description, tier: Tier}.
