{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE TypeFamilies #-}

module Pithia.Core.Class
  ( LLM (..),
    LLMStreaming (..),
    ChatEvent (..),
  )
where

import Control.Monad.Trans.Except (ExceptT)
import Data.Kind (Type)
import Data.Proxy (Proxy)
import GHC.Generics (Generic)

class LLM a where
  type Request a :: Type
  type Response a :: Type
  type Error a :: Type
  query :: Proxy a -> Request a -> ExceptT (Error a) IO (Response a)

data ChatEvent a = ChatDelta a | ChatDone | ChatUnknown String
  deriving (Generic, Show)

class (LLM a) => LLMStreaming a where
  type Chunk a :: Type
  queryStreaming ::
    Proxy a ->
    Request a ->
    (ChatEvent (Chunk a) -> IO ()) ->
    ExceptT (Error a) IO ()
