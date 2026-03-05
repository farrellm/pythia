{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

module Main (main) where

import Control.Monad.Trans.Except
import Data.Default (def)
import Data.Text qualified as T
import Pithia.Client.Anthropic
import Pithia.Client.Anthropic.API qualified as Anthropic
import Pithia.Client.Common
import Pithia.Client.OpenAI
import Pithia.Client.OpenAI.API qualified as OpenAI
import Pithia.Core.Class
import System.Environment (getEnv)
import Text.PrettyPrint.GenericPretty (pp)

main :: IO ()
main = do
  openaiToken <- getEnv "OPENAI_API_KEY"
  antApiKey <- getEnv "ANTHROPIC_API_KEY"
  let reqOpenAI =
        OpenAIRequest
          { apiKey = T.pack openaiToken,
            chatRequest =
              OpenAI.ChatRequest
                { OpenAI.model = "gpt-5-nano",
                  OpenAI.messages = [OpenAI.Message OpenAI.User "Tell me a joke."]
                }
          }
  let reqAnt =
        (def :: AnthropicRequest)
          { apiKey = T.pack antApiKey,
            chatRequest =
              def
                { -- Anthropic.model = "gpt-5-nano",
                  Anthropic.messages = [Anthropic.Message Anthropic.User "Tell me a joke."]
                }
          }
  -- runExceptT (query openAI reqOpenAI) >>= \case
  runExceptT (query anthropic reqAnt) >>= \case
    Right res -> pprint res
    Left err -> putStrLn $ "Error: " ++ show err
