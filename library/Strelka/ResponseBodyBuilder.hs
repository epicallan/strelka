module Strelka.ResponseBodyBuilder where

import Strelka.Prelude
import qualified Data.ByteString as C
import qualified Data.ByteString.Lazy as D
import qualified Data.ByteString.Builder as E
import qualified Data.Text.Encoding as H
import qualified Data.Text.Lazy as F
import qualified Data.Text.Lazy.Encoding as I
import qualified Data.Text.Lazy.Builder as J


newtype ResponseBodyBuilder =
  ResponseBodyBuilder ((ByteString -> IO ()) -> IO () -> IO ())

instance IsString ResponseBodyBuilder where
  fromString string =
    bytesBuilder (E.stringUtf8 string)

instance Monoid ResponseBodyBuilder where
  mempty =
    ResponseBodyBuilder (\_ flush -> flush)
  mappend (ResponseBodyBuilder cont1) (ResponseBodyBuilder cont2) =
    ResponseBodyBuilder (\feed flush -> cont1 feed (pure ()) *> cont2 feed flush)

instance Semigroup ResponseBodyBuilder


bytes :: ByteString -> ResponseBodyBuilder
bytes x =
  ResponseBodyBuilder (\feed flush -> feed x *> flush)

lazyBytes :: D.ByteString -> ResponseBodyBuilder
lazyBytes x =
  ResponseBodyBuilder (\feed flush -> D.foldlChunks (\io chunk -> io >> feed chunk) (pure ()) x >> flush)

bytesBuilder :: E.Builder -> ResponseBodyBuilder
bytesBuilder =
  lazyBytes . E.toLazyByteString

text :: Text -> ResponseBodyBuilder
text text =
  bytes (H.encodeUtf8 text)

lazyText :: F.Text -> ResponseBodyBuilder
lazyText text =
  ResponseBodyBuilder impl
  where
    impl feed flush =
      F.foldlChunks step (pure ()) text *> flush
      where
        step io textChunk =
          io *> feed bytesChunk
          where
            bytesChunk =
              H.encodeUtf8 textChunk

textBuilder :: J.Builder -> ResponseBodyBuilder
textBuilder =
  lazyText . J.toLazyText

