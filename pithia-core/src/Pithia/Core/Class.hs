{-# LANGUAGE TypeFamilies #-}

module Pithia.Core.Class
  ( LLM (..),
  )
where

import Control.Monad.IO.Class (MonadIO)
import Control.Monad.Trans.Except
import Data.Kind (Type)
import Data.Proxy (Proxy)

class LLM a where
  type Request a :: Type
  type Response a :: Type
  type Error a :: Type
  query :: Proxy a -> Request a -> ExceptT (Error a) IO (Response a)
