{-# LANGUAGE DataKinds #-}
{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module Pithia.Client.Anthropic
  ( AnthropicRequest (..),
    ClientError,
    anthropic,
    streamAnthropic,
  )
where

import Control.Monad.IO.Class (liftIO)
import Control.Monad.Trans.Except (ExceptT (ExceptT), throwE)
import Data.Aeson (decode)
import Data.ByteString.Lazy qualified as LBS
import Data.Default (Default (def))
import Data.Proxy (Proxy (Proxy))
import Data.Text (Text)
import Network.HTTP.Client (newManager)
import Network.HTTP.Client.TLS (tlsManagerSettings)
import Pithia.Client.Anthropic.API
import Pithia.Client.Common (onJust)
import Pithia.Core.Class
import Servant.API
import Servant.Client
import Servant.Client.Core.ServerSentEvents (EventMessage (..), EventMessageStreamT (unEventMessageStreamT))
import Servant.Client.Streaming qualified as S
import Servant.Types.SourceT (foreach)

type AnthropicKey = Header "x-api-key" Text

type AnthropicVersion = Header "anthropic-version" Text

type API =
  "v1"
    :> "messages"
    :> AnthropicKey
    :> AnthropicVersion
    :> ReqBody '[JSON] ChatRequest
    :> Post '[JSON] ChatResponse

type StreamingAPI =
  "v1"
    :> "messages"
    :> AnthropicKey
    :> AnthropicVersion
    :> ReqBody '[JSON] ChatRequest
    :> ServerSentEvents' 'POST 200 RawEvent EventMessage

api :: Proxy API
api = Proxy

streamingApi :: Proxy StreamingAPI
streamingApi = Proxy

queryAnthropic :: Maybe Text -> Maybe Text -> ChatRequest -> ClientM ChatResponse
queryAnthropic = client api

streamAnthropic :: Maybe Text -> Maybe Text -> ChatRequest -> S.ClientM (EventMessageStreamT IO)
streamAnthropic = S.client streamingApi

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

instance LLMStreaming Anthropic where
  type Chunk Anthropic = ChatChunk
  queryStreaming _ AnthropicRequest {apiKey, version, chatRequest} f = do
    manager <- liftIO $ newManager tlsManagerSettings
    let url =
          BaseUrl
            { baseUrlScheme = Https,
              baseUrlHost = "api.anthropic.com",
              baseUrlPort = 443,
              baseUrlPath = ""
            }
        env = mkClientEnv manager url
    ExceptT . liftIO $
      S.withClientM (streamAnthropic (Just apiKey) (Just version) chatRequest) env $ \case
        Left err -> pure $ Left err
        Right s -> do
          Right <$> foreach fail (onJust f . jsonChatEvent) (unEventMessageStreamT s)

jsonChatEvent :: EventMessage -> Maybe (ChatEvent ChatChunk)
jsonChatEvent EventDispatch = Nothing
jsonChatEvent (EventSetName _) = Nothing
jsonChatEvent e@(EventData b)
  | Just d <- decode (LBS.fromStrict b) =
      case d of
        MessageStop -> Just ChatDone
        Ping -> Nothing
        -- _ -> Just (ChatDelta d)
        _ -> Just . ChatUnknown $ show e
jsonChatEvent e = Just . ChatUnknown $ show e
