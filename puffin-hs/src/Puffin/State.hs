{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE OverloadedStrings #-}

{-|
Module      : Puffin.State
Description : Application state management
Copyright   : (c) 2025 jdubray
License     : MIT
Maintainer  : example@example.com

State management for the Puffin application using a functional approach.
This module handles the application state and provides operations for state transitions.
-}

module Puffin.State
    ( AppState(..)
    , AppPhase(..)
    , initialState
    , loadProject
    , saveProject
    , addPrompt
    , updatePromptStatus
    , addUserStory
    , updateStoryStatus
    ) where

import qualified Data.Map.Strict as Map
import Data.Map.Strict (Map)
import Data.Text (Text)
import Data.UUID (UUID)
import Lens.Micro.TH (makeLenses)
import Lens.Micro ((^.))

import Puffin.Models
    ( ProjectConfig
    , Prompt(..)
    , PromptStatus(..)
    , UserStory(..)
    , StoryStatus(..)
    , defaultProjectConfig
    )

-- | Application lifecycle phase
data AppPhase
    = Uninitialized
    | Initializing
    | Ready
    | Error Text
    deriving (Show, Eq)

-- | The complete application state
data AppState = AppState
    { _appPhase        :: AppPhase
    , _projectConfig   :: ProjectConfig
    , _prompts         :: Map UUID Prompt
    , _userStories     :: Map UUID UserStory
    , _currentBranch   :: Maybe Text
    , _selectedPrompt  :: Maybe UUID
    , _selectedStory   :: Maybe UUID
    } deriving (Show, Eq)

makeLenses ''AppState

-- | Initial application state
initialState :: AppState
initialState = AppState
    { _appPhase = Uninitialized
    , _projectConfig = defaultProjectConfig
    , _prompts = Map.empty
    , _userStories = Map.empty
    , _currentBranch = Nothing
    , _selectedPrompt = Nothing
    , _selectedStory = Nothing
    }

-- | Load a project from disk
loadProject :: FilePath -> IO (Either Text AppState)
loadProject projectPath = do
    -- In a full implementation, this would:
    -- 1. Read .puffin/config.json
    -- 2. Read .puffin/history.json
    -- 3. Read .puffin/stories.json
    -- 4. Construct the AppState
    return $ Left "Not implemented"

-- | Save the current project state to disk
saveProject :: AppState -> IO (Either Text ())
saveProject state = do
    -- In a full implementation, this would:
    -- 1. Write .puffin/config.json
    -- 2. Write .puffin/history.json
    -- 3. Write .puffin/stories.json
    return $ Left "Not implemented"

-- | Add a new prompt to the state
addPrompt :: Prompt -> AppState -> AppState
addPrompt prompt state =
    state { _prompts = Map.insert (promptId prompt) prompt (_prompts state) }

-- | Update the status of a prompt
updatePromptStatus :: UUID -> PromptStatus -> AppState -> AppState
updatePromptStatus promptId status state =
    state { _prompts = Map.adjust (\p -> p { promptStatus = status }) promptId (_prompts state) }

-- | Add a new user story to the state
addUserStory :: UserStory -> AppState -> AppState
addUserStory story state =
    state { _userStories = Map.insert (storyId story) story (_userStories state) }

-- | Update the status of a user story
updateStoryStatus :: UUID -> StoryStatus -> AppState -> AppState
updateStoryStatus storyId status state =
    state { _userStories = Map.adjust (\s -> s { storyStatus = status }) storyId (_userStories state) }
