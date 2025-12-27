{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

{-|
Module      : Puffin.Models
Description : Core data models for Puffin
Copyright   : (c) 2025 jdubray
License     : MIT
Maintainer  : example@example.com

Data models representing the core entities in Puffin:
- Projects
- Prompts
- User Stories
- Configuration
-}

module Puffin.Models
    ( ClaudeModel(..)
    , ProjectConfig(..)
    , Prompt(..)
    , PromptStatus(..)
    , UserStory(..)
    , StoryStatus(..)
    , Branch(..)
    , GuidanceOptions(..)
    , ProgrammingStyle(..)
    , TestingApproach(..)
    , DocumentationLevel(..)
    , defaultProjectConfig
    , defaultGuidanceOptions
    ) where

import Data.Aeson (FromJSON, ToJSON)
import Data.Text (Text)
import Data.Time (UTCTime)
import Data.UUID (UUID)
import GHC.Generics (Generic)

-- | Available Claude models
data ClaudeModel
    = Opus      -- ^ Most capable, best for complex tasks
    | Sonnet    -- ^ Balanced performance and speed
    | Haiku     -- ^ Fast and lightweight
    deriving (Show, Eq, Ord, Generic)

instance FromJSON ClaudeModel
instance ToJSON ClaudeModel

-- | Programming style preferences
data ProgrammingStyle
    = OOP           -- ^ Object-Oriented Programming
    | FP            -- ^ Functional Programming
    | TemporalLogic -- ^ Temporal Logic
    | Hybrid        -- ^ Hybrid approach
    deriving (Show, Eq, Generic)

instance FromJSON ProgrammingStyle
instance ToJSON ProgrammingStyle

-- | Testing approach preferences
data TestingApproach
    = TDD              -- ^ Test-Driven Development
    | BDD              -- ^ Behavior-Driven Development
    | IntegrationFirst -- ^ Integration tests first
    deriving (Show, Eq, Generic)

instance FromJSON TestingApproach
instance ToJSON TestingApproach

-- | Documentation level preferences
data DocumentationLevel
    = Minimal       -- ^ Minimal documentation
    | Standard      -- ^ Standard documentation
    | Comprehensive -- ^ Comprehensive documentation
    deriving (Show, Eq, Generic)

instance FromJSON DocumentationLevel
instance ToJSON DocumentationLevel

-- | Claude guidance options
data GuidanceOptions = GuidanceOptions
    { programmingStyle   :: ProgrammingStyle
    , testingApproach    :: TestingApproach
    , documentationLevel :: DocumentationLevel
    , errorHandling      :: Text
    , namingConvention   :: Text
    , commentStyle       :: Text
    } deriving (Show, Eq, Generic)

instance FromJSON GuidanceOptions
instance ToJSON GuidanceOptions

-- | Project configuration
data ProjectConfig = ProjectConfig
    { projectName        :: Text
    , projectDescription :: Text
    , projectPath        :: FilePath
    , defaultModel       :: ClaudeModel
    , guidanceOptions    :: GuidanceOptions
    , architecture       :: Maybe Text
    , assumptions        :: [Text]
    , dataModel          :: Maybe Text
    } deriving (Show, Eq, Generic)

instance FromJSON ProjectConfig
instance ToJSON ProjectConfig

-- | Prompt execution status
data PromptStatus
    = Idle
    | Composing
    | Submitted
    | Streaming
    | Completed
    | Failed Text
    deriving (Show, Eq, Generic)

instance FromJSON PromptStatus
instance ToJSON PromptStatus

-- | A conversation branch
data Branch
    = Specifications
    | Architecture
    | UI
    | Backend
    | Deployment
    | Custom Text
    deriving (Show, Eq, Generic)

instance FromJSON Branch
instance ToJSON Branch

-- | A prompt in the conversation
data Prompt = Prompt
    { promptId       :: UUID
    , promptText     :: Text
    , promptResponse :: Maybe Text
    , promptStatus   :: PromptStatus
    , promptBranch   :: Branch
    , promptParent   :: Maybe UUID
    , promptChildren :: [UUID]
    , promptCreated  :: UTCTime
    , promptModel    :: ClaudeModel
    , isCompleted    :: Bool
    } deriving (Show, Eq, Generic)

instance FromJSON Prompt
instance ToJSON Prompt

-- | User story status
data StoryStatus
    = Pending
    | InProgress
    | StoryCompleted
    | Archived
    deriving (Show, Eq, Generic)

instance FromJSON StoryStatus
instance ToJSON StoryStatus

-- | A user story
data UserStory = UserStory
    { storyId          :: UUID
    , storyTitle       :: Text
    , storyDescription :: Text
    , storyStatus      :: StoryStatus
    , storyCreated     :: UTCTime
    , storyCompleted   :: Maybe UTCTime
    , acceptanceCriteria :: [Text]
    } deriving (Show, Eq, Generic)

instance FromJSON UserStory
instance ToJSON UserStory

-- | Default project configuration
defaultProjectConfig :: ProjectConfig
defaultProjectConfig = ProjectConfig
    { projectName = "New Project"
    , projectDescription = ""
    , projectPath = ""
    , defaultModel = Opus
    , guidanceOptions = defaultGuidanceOptions
    , architecture = Nothing
    , assumptions = []
    , dataModel = Nothing
    }

-- | Default guidance options
defaultGuidanceOptions :: GuidanceOptions
defaultGuidanceOptions = GuidanceOptions
    { programmingStyle = Hybrid
    , testingApproach = TDD
    , documentationLevel = Standard
    , errorHandling = "exceptions"
    , namingConvention = "camelCase"
    , commentStyle = "JSDoc"
    }
