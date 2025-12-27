{-# LANGUAGE OverloadedStrings #-}

{-|
Module      : Puffin.ClaudeService
Description : Claude Code CLI integration
Copyright   : (c) 2025 jdubray
License     : MIT
Maintainer  : example@example.com

Integration with the Claude Code CLI for executing prompts.
This module handles spawning the Claude process and streaming responses.
-}

module Puffin.ClaudeService
    ( ClaudeHandle
    , startClaude
    , stopClaude
    , sendPrompt
    , ClaudeResponse(..)
    ) where

import Control.Concurrent (forkIO, threadDelay)
import Control.Concurrent.MVar (MVar, newMVar, takeMVar, putMVar)
import Control.Monad (forever, void)
import Data.Text (Text)
import qualified Data.Text as T
import System.Process
    ( ProcessHandle
    , CreateProcess(..)
    , StdStream(..)
    , proc
    , createProcess
    , terminateProcess
    , waitForProcess
    )
import System.IO (Handle, hGetLine, hPutStrLn, hFlush, hClose)

-- | A handle to a running Claude process
data ClaudeHandle = ClaudeHandle
    { processHandle :: ProcessHandle
    , stdinHandle   :: Handle
    , stdoutHandle  :: Handle
    , stderrHandle  :: Handle
    , responseMVar  :: MVar Text
    }

-- | A response from Claude
data ClaudeResponse
    = StreamingText Text
    | ToolExecution Text
    | Completed Text
    | ErrorResponse Text
    deriving (Show, Eq)

-- | Start a Claude Code CLI subprocess
startClaude :: FilePath -> IO (Either Text ClaudeHandle)
startClaude projectPath = do
    let claudeProc = (proc "claude" ["--json"])
            { cwd = Just projectPath
            , std_in = CreatePipe
            , std_out = CreatePipe
            , std_err = CreatePipe
            }
    
    result <- createProcess claudeProc
    case result of
        (Just hIn, Just hOut, Just hErr, ph) -> do
            mvar <- newMVar ""
            
            -- Start background thread to read output
            void $ forkIO $ forever $ do
                line <- hGetLine hOut
                _ <- takeMVar mvar
                putMVar mvar (T.pack line)
                threadDelay 100000  -- 100ms
            
            let handle = ClaudeHandle
                    { processHandle = ph
                    , stdinHandle = hIn
                    , stdoutHandle = hOut
                    , stderrHandle = hErr
                    , responseMVar = mvar
                    }
            return $ Right handle
        _ -> return $ Left "Failed to start Claude process"

-- | Stop a running Claude process
stopClaude :: ClaudeHandle -> IO ()
stopClaude handle = do
    hClose (stdinHandle handle)
    hClose (stdoutHandle handle)
    hClose (stderrHandle handle)
    terminateProcess (processHandle handle)
    void $ waitForProcess (processHandle handle)

-- | Send a prompt to Claude and get responses
sendPrompt :: ClaudeHandle -> Text -> IO (Either Text [ClaudeResponse])
sendPrompt handle prompt = do
    -- Write prompt to stdin
    hPutStrLn (stdinHandle handle) (T.unpack prompt)
    hFlush (stdinHandle handle)
    
    -- In a full implementation, this would:
    -- 1. Stream responses from stdout
    -- 2. Parse JSON messages
    -- 3. Handle different message types (text, tool_use, error)
    -- 4. Return a stream of ClaudeResponse values
    
    threadDelay 1000000  -- Wait 1 second (placeholder)
    return $ Right [Completed "Response placeholder"]
