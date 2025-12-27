{-# LANGUAGE OverloadedStrings #-}

{-|
Module      : Main
Description : Puffin entry point
Copyright   : (c) 2025 jdubray
License     : MIT
Maintainer  : example@example.com

Main entry point for the Puffin Haskell application.
-}

module Main where

import System.Environment (getArgs)
import System.Directory (doesDirectoryExist)
import Control.Monad (when)
import Data.Text (Text)
import qualified Data.Text as T

import Puffin.State (initialState, loadProject)
import Puffin.UI (runUI)

-- | Main function
main :: IO ()
main = do
    args <- getArgs
    
    case args of
        [] -> do
            putStrLn "Puffin - Haskell Edition"
            putStrLn "Usage: puffin-hs-exe <project-directory>"
            putStrLn ""
            putStrLn "Please provide a project directory to open."
            
        (projectPath:_) -> do
            -- Check if directory exists
            exists <- doesDirectoryExist projectPath
            if not exists
                then do
                    putStrLn $ "Error: Directory does not exist: " ++ projectPath
                else do
                    putStrLn $ "Opening project: " ++ projectPath
                    putStrLn "Loading project state..."
                    
                    -- Try to load existing project state
                    result <- loadProject projectPath
                    case result of
                        Left err -> do
                            putStrLn $ "Note: " ++ T.unpack err
                            putStrLn "Starting with fresh state..."
                            runUI initialState
                        Right appState -> do
                            putStrLn "Project loaded successfully!"
                            runUI appState
