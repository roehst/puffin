{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}

{-|
Module      : Puffin.UI
Description : Terminal user interface using Brick
Copyright   : (c) 2025 jdubray
License     : MIT
Maintainer  : example@example.com

Terminal-based user interface for Puffin using the Brick library.
-}

module Puffin.UI
    ( runUI
    , UIState
    ) where

import Control.Monad (void)
import Brick
import Brick.Widgets.Border (border, borderWithLabel)
import Brick.Widgets.Center (center, hCenter)
import Brick.Widgets.Edit (Editor, editor, renderEditor, handleEditorEvent, getEditContents)
import qualified Brick.Widgets.List as L
import qualified Data.Vector as Vec
import Graphics.Vty (Event(..), Key(..), Modifier(..), defAttr)
import Lens.Micro ((^.))
import Lens.Micro.TH (makeLenses)
import Data.Text (Text)
import qualified Data.Text as T

import Puffin.State (AppState, AppPhase(..))
import qualified Puffin.State as State

-- | UI resource names
data Name
    = PromptEditor
    | ProjectList
    | StoryList
    deriving (Show, Eq, Ord)

-- | Available views in the application
data View
    = ProjectView
    | PromptView
    | BacklogView
    | ArchitectureView
    | GitView
    deriving (Show, Eq)

-- | UI-specific state
data UIState = UIState
    { _appState      :: AppState
    , _promptEditor  :: Editor Text Name
    , _currentView   :: View
    , _statusMessage :: Maybe Text
    }

makeLenses ''UIState

-- | Initial UI state
initialUIState :: AppState -> UIState
initialUIState appSt = UIState
    { _appState = appSt
    , _promptEditor = editor PromptEditor (Just 1) ""
    , _currentView = ProjectView
    , _statusMessage = Nothing
    }

-- | Draw the UI
drawUI :: UIState -> [Widget Name]
drawUI st = [ui]
  where
    ui = vBox
        [ drawHeader st
        , drawMainContent st
        , drawFooter st
        ]

-- | Draw the header
drawHeader :: UIState -> Widget Name
drawHeader st =
    borderWithLabel (str "Puffin - Haskell Edition") $
    hCenter $ str "A GUI for Claude Code"

-- | Draw the main content area
drawMainContent :: UIState -> Widget Name
drawMainContent st =
    case _currentView st of
        ProjectView -> drawProjectView st
        PromptView -> drawPromptView st
        BacklogView -> drawBacklogView st
        ArchitectureView -> drawArchitectureView st
        GitView -> drawGitView st

-- | Draw the project view
drawProjectView :: UIState -> Widget Name
drawProjectView st =
    border $ padAll 1 $ vBox
        [ str "Project Configuration"
        , str " "
        , str "Press 'p' for Prompt View"
        , str "Press 'b' for Backlog View"
        , str "Press 'a' for Architecture View"
        , str "Press 'g' for Git View"
        , str "Press 'q' to quit"
        ]

-- | Draw the prompt view
drawPromptView :: UIState -> Widget Name
drawPromptView st =
    vBox
        [ border $ vBox
            [ str "Prompt History"
            , str "(Empty)"
            ]
        , border $ vBox
            [ str "Enter Prompt:"
            , renderEditor (txt . T.unlines) True (_promptEditor st)
            ]
        ]

-- | Draw the backlog view
drawBacklogView :: UIState -> Widget Name
drawBacklogView st =
    border $ padAll 1 $ vBox
        [ str "User Stories Backlog"
        , str " "
        , str "No stories yet."
        ]

-- | Draw the architecture view
drawArchitectureView :: UIState -> Widget Name
drawArchitectureView st =
    border $ padAll 1 $ vBox
        [ str "Architecture Documentation"
        , str " "
        , str "No architecture defined."
        ]

-- | Draw the git view
drawGitView :: UIState -> Widget Name
drawGitView st =
    border $ padAll 1 $ vBox
        [ str "Git Integration"
        , str " "
        , str "Current branch: (unknown)"
        ]

-- | Draw the footer
drawFooter :: UIState -> Widget Name
drawFooter st =
    hBox
        [ str "View: "
        , str (show $ _currentView st)
        , str " | "
        , str "Press '?' for help"
        , fill ' '
        , case _statusMessage st of
            Just msg -> txt msg
            Nothing -> str ""
        ]

-- | Handle events
handleEvent :: BrickEvent Name e -> EventM Name UIState ()
handleEvent (VtyEvent (EvKey (KChar 'q') [])) = halt
handleEvent (VtyEvent (EvKey (KChar 'p') [])) = modify $ \st -> st { _currentView = PromptView }
handleEvent (VtyEvent (EvKey (KChar 'b') [])) = modify $ \st -> st { _currentView = BacklogView }
handleEvent (VtyEvent (EvKey (KChar 'a') [])) = modify $ \st -> st { _currentView = ArchitectureView }
handleEvent (VtyEvent (EvKey (KChar 'g') [])) = modify $ \st -> st { _currentView = GitView }
handleEvent (VtyEvent (EvKey (KChar 'h') [])) = modify $ \st -> st { _currentView = ProjectView }
handleEvent ev = do
    st <- get
    case _currentView st of
        PromptView -> zoom promptEditor $ handleEditorEvent ev
        _ -> return ()

-- | Application definition
app :: App UIState e Name
app = App
    { appDraw = drawUI
    , appChooseCursor = showFirstCursor
    , appHandleEvent = handleEvent
    , appStartEvent = return ()
    , appAttrMap = const $ attrMap defAttr []
    }

-- | Run the UI
runUI :: AppState -> IO ()
runUI appSt = do
    let initialSt = initialUIState appSt
    void $ defaultMain app initialSt
