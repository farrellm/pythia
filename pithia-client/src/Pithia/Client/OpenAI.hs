{-# LANGUAGE DataKinds #-}
{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module Pithia.Client.OpenAI
  ( OpenAIRequest (..),
    ClientError,
    openAI,
    streamGPT,
  )
where

import Control.Monad.IO.Class (liftIO)
import Control.Monad.Trans.Except (ExceptT (ExceptT), throwE)
import Data.Aeson (FromJSON, decode)
import Data.ByteString.Lazy qualified as LBS
import Data.Proxy (Proxy (Proxy))
import Data.Text (Text)
import Network.HTTP.Client (newManager)
import Network.HTTP.Client.TLS (tlsManagerSettings)
import Pithia.Client.Common (onJust)
import Pithia.Client.OpenAI.API
import Pithia.Core.Class
import Servant.API
import Servant.Client
import Servant.Client.Core.ServerSentEvents (EventMessage (..), EventMessageStreamT (unEventMessageStreamT))
import Servant.Client.Streaming qualified as S
import Servant.Types.SourceT (foreach)

type OpenAIAuth = Header "Authorization" Text

type API =
  "v1"
    :> "chat"
    :> "completions"
    :> OpenAIAuth
    :> ReqBody '[JSON] ChatRequest
    :> Post '[JSON] ChatResponse

type StreamingAPI =
  "v1"
    :> "chat"
    :> "completions"
    :> OpenAIAuth
    :> ReqBody '[JSON] ChatRequest
    :> ServerSentEvents' 'POST 200 RawEvent EventMessage

api :: Proxy API
api = Proxy

streamingApi :: Proxy StreamingAPI
streamingApi = Proxy

queryGPT :: Maybe Text -> ChatRequest -> ClientM ChatResponse
queryGPT = client api

streamGPT :: Maybe Text -> ChatRequest -> S.ClientM (EventMessageStreamT IO)
streamGPT = S.client streamingApi

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

instance LLMStreaming OpenAI where
  type Chunk OpenAI = ChatChunk
  queryStreaming _ OpenAIRequest {apiKey, chatRequest} f = do
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
    ExceptT . liftIO $
      S.withClientM (streamGPT (Just authHeader) chatRequest) env $ \case
        Left err -> pure $ Left err
        Right s -> do
          Right <$> foreach fail (onJust f . jsonChatEvent) (unEventMessageStreamT s)

jsonChatEvent :: (FromJSON a) => EventMessage -> Maybe (ChatEvent a)
jsonChatEvent EventDispatch = Nothing
jsonChatEvent (EventData b)
  | Just d <- decode (LBS.fromStrict b) = Just (ChatDelta d)
  | b == "[DONE]" = Just ChatDone
jsonChatEvent e = Just . ChatUnknown $ show e
