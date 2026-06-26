{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module Lib
  ( testOpenAI,
    testStreamOpenAI,
    testAnthropic,
    testAnthropicStream,
    runTest,
  )
where

import Control.Monad.Trans.Except (runExceptT)
import Data.Default (def)
import Data.Text qualified as T
import Pythia.Client.Anthropic as Anthropic
import Pythia.Client.Anthropic.API qualified as Anthropic
import Pythia.Client.Common (pprint)
import Pythia.Client.OpenAI
import Pythia.Client.OpenAI.API qualified as OpenAI
import Pythia.Core.Class
import System.Environment (getEnv)

testOpenAI :: IO ()
testOpenAI = do
  openaiToken <- getEnv "OPENAI_API_KEY"
  let reqOpenAI =
        OpenAIRequest
          { apiKey = T.pack openaiToken,
            chatRequest =
              OpenAI.ChatRequest
                { OpenAI.model = "gpt-5-nano",
                  OpenAI.messages =
                    [ OpenAI.Message
                        { role = OpenAI.User,
                          content = "Tell me a joke."
                        }
                    ],
                  OpenAI.stream = Nothing
                }
          }
  runExceptT (query openAI reqOpenAI) >>= \case
    Right res -> pprint res
    Left err -> putStrLn $ "Error: " ++ show err

testStreamOpenAI :: IO ()
testStreamOpenAI = do
  openaiToken <- getEnv "OPENAI_API_KEY"
  let reqOpenAI =
        OpenAIRequest
          { apiKey = T.pack openaiToken,
            chatRequest =
              OpenAI.ChatRequest
                { OpenAI.model = "gpt-5-nano",
                  OpenAI.messages =
                    [ OpenAI.Message
                        { role = OpenAI.User,
                          content = "Tell me a joke."
                        }
                    ],
                  OpenAI.stream = Just True
                }
          }
  runExceptT (queryStreaming openAI reqOpenAI print) >>= \case
    Right () -> pure ()
    Left err -> putStrLn $ "Error: " ++ show err

testAnthropic :: IO ()
testAnthropic = do
  antApiKey <- getEnv "ANTHROPIC_API_KEY"
  let reqAnt =
        (def :: AnthropicRequest)
          { Anthropic.apiKey = T.pack antApiKey,
            chatRequest =
              def
                { Anthropic.messages =
                    [ Anthropic.Message
                        { Anthropic.role = Anthropic.User,
                          Anthropic.content = "Tell me a joke."
                        }
                    ]
                }
          }
  pprint reqAnt.chatRequest
  runExceptT (query anthropic reqAnt) >>= \case
    Right res -> pprint res
    Left err -> putStrLn $ "Error: " ++ show err

testAnthropicStream :: IO ()
testAnthropicStream = do
  antApiKey <- getEnv "ANTHROPIC_API_KEY"
  let reqAnt =
        (def :: AnthropicRequest)
          { Anthropic.apiKey = T.pack antApiKey,
            chatRequest =
              def
                { Anthropic.messages =
                    [ Anthropic.Message
                        { Anthropic.role = Anthropic.User,
                          Anthropic.content = "Tell me a joke."
                        }
                    ],
                  Anthropic.stream = Just True
                }
          }
  pprint reqAnt.chatRequest
  runExceptT (queryStreaming anthropic reqAnt print) >>= \case
    Right () -> pure ()
    Left err -> putStrLn $ "Error: " ++ show err

runTest :: IO ()
runTest = testAnthropicStream
