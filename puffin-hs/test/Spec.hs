{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Test.Hspec
import qualified Data.Map.Strict as Map

import Puffin.Models
import Puffin.State

main :: IO ()
main = hspec $ do
    describe "Puffin.Models" $ do
        it "creates default project config" $ do
            let config = defaultProjectConfig
            projectName config `shouldBe` "New Project"
            defaultModel config `shouldBe` Opus
        
        it "creates default guidance options" $ do
            let opts = defaultGuidanceOptions
            programmingStyle opts `shouldBe` Hybrid
            testingApproach opts `shouldBe` TDD
            documentationLevel opts `shouldBe` Standard
    
    describe "Puffin.State" $ do
        it "initializes with empty state" $ do
            let state = initialState
            _appPhase state `shouldBe` Uninitialized
            Map.size (_prompts state) `shouldBe` 0
            Map.size (_userStories state) `shouldBe` 0
