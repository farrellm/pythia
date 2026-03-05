{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module Pithia.Client.Anthropic
  ( AnthropicRequest (..),
    ClientError,
    anthropic,
  )
where

import Control.Monad.IO.Class (liftIO)
import Control.Monad.Trans.Except
import Data.Default (Default (def))
import Data.Proxy
import Data.Text (Text)
import Network.HTTP.Conduit hiding (Proxy)
import Pithia.Client.Anthropic.API
import Pithia.Core.Class
import Servant.API
import Servant.Client

type AnthropicKey = Header "x-api-key" Text

type AnthropicVersion = Header "anthropic-version" Text

type API =
  "v1"
    :> "messages"
    :> AnthropicKey
    :> AnthropicVersion
    :> ReqBody '[JSON] ChatRequest
    :> Post '[JSON] ChatResponse

api :: Proxy API
api = Proxy

queryAnthropic :: Maybe Text -> Maybe Text -> ChatRequest -> ClientM ChatResponse
queryAnthropic = client api

data Anthropic

anthropic :: Proxy Anthropic
anthropic = Proxy

data AnthropicRequest = AnthropicRequest
  { apiKey :: Text,
    version :: Text,
    chatRequest :: ChatRequest
  }

instance Default AnthropicRequest where
  def =
    AnthropicRequest
      { apiKey = "",
        version = "2023-06-01",
        chatRequest = def
      }

instance LLM Anthropic where
  type Request Anthropic = AnthropicRequest
  type Response Anthropic = ChatResponse
  type Error Anthropic = ClientError

  query _ AnthropicRequest {apiKey, version, chatRequest} = do
    manager <- liftIO $ newManager tlsManagerSettings
    let url =
          BaseUrl
            { baseUrlScheme = Https,
              baseUrlHost = "api.anthropic.com",
              baseUrlPort = 443,
              baseUrlPath = ""
            }
        env = mkClientEnv manager url
    res <- liftIO $ runClientM (queryAnthropic (Just apiKey) (Just version) chatRequest) env
    case res of
      Left err -> throwE err
      Right response -> pure response
