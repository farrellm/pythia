{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module Pithia.Client.OpenAI
  ( OpenAIRequest (..),
    ClientError,
    openAI,
  )
where

import Control.Monad.IO.Class (liftIO)
import Control.Monad.Trans.Except (throwE)
import Data.Proxy (Proxy (Proxy))
import Data.Text (Text)
import Network.HTTP.Conduit hiding (Proxy)
import Pithia.Client.OpenAI.API
import Pithia.Core.Class
import Servant.API
import Servant.Client

type OpenAIAuth = Header "Authorization" Text

type API =
  "v1"
    :> "chat"
    :> "completions"
    :> OpenAIAuth
    :> ReqBody '[JSON] ChatRequest
    :> Post '[JSON] ChatResponse

api :: Proxy API
api = Proxy

queryGPT :: Maybe Text -> ChatRequest -> ClientM ChatResponse
queryGPT = client api

data OpenAI

openAI :: Proxy OpenAI
openAI = Proxy

data OpenAIRequest = OpenAIRequest
  { apiKey :: Text,
    chatRequest :: ChatRequest
  }

instance LLM OpenAI where
  type Request OpenAI = OpenAIRequest
  type Response OpenAI = ChatResponse
  type Error OpenAI = ClientError

  query _ OpenAIRequest {apiKey, chatRequest} = do
    manager <- liftIO $ newManager tlsManagerSettings
    let url =
          BaseUrl
            { baseUrlScheme = Https,
              baseUrlHost = "api.openai.com",
              baseUrlPort = 443,
              baseUrlPath = ""
            }
        env = mkClientEnv manager url
        authHeader = "Bearer " <> apiKey
    res <- liftIO $ runClientM (queryGPT (Just authHeader) chatRequest) env
    case res of
      Left err -> throwE err
      Right response -> pure response
