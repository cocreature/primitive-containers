{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE MagicHash #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE TypeFamilies #-}

{-# OPTIONS_GHC -O2 #-}
module Data.Set.Unlifted
  ( Set
  , singleton
  , member
  , size
  ) where

import Data.Primitive.UnliftedArray (PrimUnlifted(..))
import Data.Semigroup (Semigroup)
import qualified Data.Foldable as F
import qualified Data.Semigroup as SG
import qualified GHC.Exts as E
import qualified Internal.Set.Unlifted as I

-- | A set of elements.
newtype Set a = Set (I.Set a)

instance PrimUnlifted (Set a) where
  toArrayArray# (Set x) = toArrayArray# x
  fromArrayArray# y = Set (fromArrayArray# y)

instance (PrimUnlifted a, Ord a) => Semigroup (Set a) where
  Set x <> Set y = Set (I.append x y)
  stimes = SG.stimesIdempotentMonoid
  sconcat xs = Set (I.concat (E.coerce (F.toList xs)))

instance (PrimUnlifted a, Ord a) => Monoid (Set a) where
  mempty = Set I.empty
  mappend = (SG.<>)
  mconcat xs = Set (I.concat (E.coerce xs))

instance (PrimUnlifted a, Eq a) => Eq (Set a) where
  Set x == Set y = I.equals x y

instance (PrimUnlifted a, Ord a) => Ord (Set a) where
  compare (Set x) (Set y) = I.compare x y

-- | The functions that convert a list to a 'Set' are asymptotically
-- better that using @'foldMap' 'singleton'@, with a cost of /O(n*log n)/
-- rather than /O(n^2)/. If the input list is sorted, even if duplicate
-- elements are present, the algorithm further improves to /O(n)/. The
-- fastest option available is calling 'fromListN' on a presorted list
-- and passing the correct size size of the resulting 'Set'. However, even
-- if an incorrect size is given to this function,
-- it will still correctly convert the list into a 'Set'.
instance (PrimUnlifted a, Ord a) => E.IsList (Set a) where
  type Item (Set a) = a
  fromListN n = Set . I.fromListN n
  fromList = Set . I.fromList
  toList (Set s) = I.toList s

instance (PrimUnlifted a, Show a) => Show (Set a) where
  showsPrec p (Set s) = I.showsPrec p s

-- | Test for membership in the set.
member :: (PrimUnlifted a, Ord a) => a -> Set a -> Bool
member a (Set s) = I.member a s

-- | Construct a set with a single element.
singleton :: PrimUnlifted a => a -> Set a
singleton = Set . I.singleton

-- | The number of elements in the set.
size :: PrimUnlifted a => Set a -> Int
size (Set s) = I.size s


