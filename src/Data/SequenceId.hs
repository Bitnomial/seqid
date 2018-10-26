{-# LANGUAGE GeneralizedNewtypeDeriving #-}

module Data.SequenceId
       ( checkSeqId
       , incrementSeqId

         -- * Monadic
       , checkSeqIdM
       , incrementSeqIdM
       , lastSeqIdM
       , SequenceIdT (..)
       , runSequenceIdT
       , execSequenceIdT
       , evalSequenceIdT

         -- * Types
       , SequenceIdError (..)
       , SequenceIdErrorType (..)
       ) where


import           Control.Applicative       (Applicative)
import           Control.Monad.State.Class (MonadState, get, modify', put)
import           Control.Monad.Trans.Class (MonadTrans)
import           Control.Monad.Trans.State (StateT (..), evalStateT, execStateT)


newtype SequenceIdT s m a = SequenceIdT { unSequenceIdT :: StateT s m a }
    deriving (Monad, Applicative, Functor, MonadState s, MonadTrans)


evalSequenceIdT :: Monad m => SequenceIdT s m b -> s -> m b
evalSequenceIdT = evalStateT . unSequenceIdT


execSequenceIdT :: Monad m => SequenceIdT s m b -> s -> m s
execSequenceIdT = execStateT . unSequenceIdT


runSequenceIdT :: Monad m => SequenceIdT s m b -> s -> m (b, s)
runSequenceIdT = runStateT . unSequenceIdT


data SequenceIdError a = SequenceIdError
    { errType   :: !SequenceIdErrorType
    , lastSeqId :: !a
    , currSeqId :: !a
    } deriving (Eq, Show)


data SequenceIdErrorType
    = SequenceIdDropped
    | SequenceIdDuplicated
    deriving (Eq, Show)


-- | If the current sequence ID is greater than 1 more than the last
-- sequence ID then the appropriate error is returned.
checkSeqIdM :: (Integral a, Monad m)
            => a -- ^ Current sequence ID
            -> SequenceIdT a m (Maybe (SequenceIdError a))
checkSeqIdM currSeq = do
    lastSeq <- get
    put $ max lastSeq currSeq
    return $ checkSeqId lastSeq currSeq


-- | If the difference between the sequence IDs is not 1 then the
-- appropriate error is returned.
checkSeqId :: Integral a
           => a -- ^ Last sequence ID
           -> a -- ^ Current sequence ID
           -> Maybe (SequenceIdError a)
checkSeqId lastSeq currSeq
    | delta lastSeq currSeq > 1 = Just $ SequenceIdError SequenceIdDropped    lastSeq currSeq
    | delta lastSeq currSeq < 1 = Just $ SequenceIdError SequenceIdDuplicated lastSeq currSeq
    | otherwise                 = Nothing


delta :: Integral a => a -> a -> Int
delta lastSeq currSeq = fromIntegral currSeq - fromIntegral lastSeq


-- | Update to the next sequense ID
incrementSeqIdM :: (Monad m, Integral a) => SequenceIdT a m a -- ^ Next sequence ID
incrementSeqIdM = modify' incrementSeqId >> get


-- | Increment to the next sequense ID
incrementSeqId :: Integral a
               => a -- ^ Last sequence ID
               -> a -- ^ Next sequence ID
incrementSeqId = (+1)


-- | Last seen sequense ID
lastSeqIdM :: Monad m => SequenceIdT a m a -- ^ Last sequence ID
lastSeqIdM = get
