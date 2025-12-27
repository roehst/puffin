{-# LANGUAGE OverloadedStrings #-}

{-|
Module      : Puffin.GitService
Description : Git integration for project management
Copyright   : (c) 2025 jdubray
License     : MIT
Maintainer  : example@example.com

Git operations for managing project repositories.
-}

module Puffin.GitService
    ( GitStatus(..)
    , getStatus
    , createBranch
    , switchBranch
    , stageFiles
    , commit
    , mergeBranch
    ) where

import Data.Text (Text)
import qualified Data.Text as T
import System.Process (readProcessWithExitCode)
import System.Exit (ExitCode(..))

-- | Git repository status
data GitStatus = GitStatus
    { currentBranch   :: Text
    , modifiedFiles   :: [FilePath]
    , stagedFiles     :: [FilePath]
    , untrackedFiles  :: [FilePath]
    } deriving (Show, Eq)

-- | Run a git command and return the output
runGit :: FilePath -> [String] -> IO (Either Text Text)
runGit projectPath args = do
    (exitCode, stdout, stderr) <- readProcessWithExitCode "git" ("-C" : projectPath : args) ""
    case exitCode of
        ExitSuccess -> return $ Right (T.pack stdout)
        ExitFailure _ -> return $ Left (T.pack stderr)

-- | Get the current git status
getStatus :: FilePath -> IO (Either Text GitStatus)
getStatus projectPath = do
    -- Get current branch
    branchResult <- runGit projectPath ["branch", "--show-current"]
    case branchResult of
        Left err -> return $ Left err
        Right branch -> do
            -- Get status
            statusResult <- runGit projectPath ["status", "--porcelain"]
            case statusResult of
                Left err -> return $ Left err
                Right statusOutput -> do
                    let status = parseGitStatus (T.strip branch) statusOutput
                    return $ Right status

-- | Parse git status output
parseGitStatus :: Text -> Text -> GitStatus
parseGitStatus branch output =
    let lines' = T.lines output
        modified = [T.unpack $ T.strip $ T.drop 3 line | line <- lines', " M" `T.isPrefixOf` line]
        staged = [T.unpack $ T.strip $ T.drop 3 line | line <- lines', "M " `T.isPrefixOf` line]
        untracked = [T.unpack $ T.strip $ T.drop 3 line | line <- lines', "??" `T.isPrefixOf` line]
    in GitStatus
        { currentBranch = branch
        , modifiedFiles = modified
        , stagedFiles = staged
        , untrackedFiles = untracked
        }

-- | Create a new branch
createBranch :: FilePath -> Text -> IO (Either Text ())
createBranch projectPath branchName = do
    result <- runGit projectPath ["checkout", "-b", T.unpack branchName]
    case result of
        Left err -> return $ Left err
        Right _ -> return $ Right ()

-- | Switch to a different branch
switchBranch :: FilePath -> Text -> IO (Either Text ())
switchBranch projectPath branchName = do
    result <- runGit projectPath ["checkout", T.unpack branchName]
    case result of
        Left err -> return $ Left err
        Right _ -> return $ Right ()

-- | Stage files for commit
stageFiles :: FilePath -> [FilePath] -> IO (Either Text ())
stageFiles projectPath files = do
    result <- runGit projectPath ("add" : files)
    case result of
        Left err -> return $ Left err
        Right _ -> return $ Right ()

-- | Commit staged changes
commit :: FilePath -> Text -> IO (Either Text ())
commit projectPath message = do
    result <- runGit projectPath ["commit", "-m", T.unpack message]
    case result of
        Left err -> return $ Left err
        Right _ -> return $ Right ()

-- | Merge a branch into the current branch
mergeBranch :: FilePath -> Text -> IO (Either Text ())
mergeBranch projectPath branchName = do
    result <- runGit projectPath ["merge", T.unpack branchName]
    case result of
        Left err -> return $ Left err
        Right _ -> return $ Right ()
