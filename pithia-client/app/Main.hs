{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Control.Monad.Trans.Except
import Data.Text qualified as T
import Pithia.Client.OpenAI
import Pithia.Client.OpenAI.API
import Pithia.Core.Class
import System.Environment (getEnv)

main :: IO ()
main = do
  tok <- getEnv "OPENAI_API_KEY"
  let req =
        OpenAIRequest
          { token = T.pack tok,
            chatRequest =
              ChatRequest
                { model = "gpt-5-nano",
                  messages = [Message User "Tell me a joke."]
                }
          }
  runExceptT (query openAI req) >>= \case
    Right res -> print res
    Left err -> putStrLn $ "Error: " ++ show err
