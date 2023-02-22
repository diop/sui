// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

// tests vector of objects

//# init --addresses Test=0x0 --accounts A

//# publish
module Test::M {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use std::vector;

    struct Obj has key, store {
        id: UID,
        value: u64
    }

    struct AnotherObj has key {
        id: UID,
        value: u64
    }

    public entry fun mint(v: u64, ctx: &mut TxContext) {
        transfer::transfer(
            Obj {
                id: object::new(ctx),
                value: v,
            },
            tx_context::sender(ctx),
        )
    }

    public entry fun mint_another(v: u64, ctx: &mut TxContext) {
        transfer::transfer(
            AnotherObj {
                id: object::new(ctx),
                value: v,
            },
            tx_context::sender(ctx),
        )
    }

    public entry fun mint_child(v: u64, parent: &mut Obj, ctx: &mut TxContext) {
        sui::dynamic_object_field::add(
            &mut parent.id, 0,
            Obj {
                id: object::new(ctx),
                value: v,
            },
        )
    }

    public entry fun mint_shared(v: u64, ctx: &mut TxContext) {
        transfer::share_object(
            Obj {
                id: object::new(ctx),
                value: v,
            }
        )
    }

    public entry fun prim_vec_len(v: vector<u64>, _: &mut TxContext) {
        assert!(vector::length(&v) == 2, 0);
    }

    public entry fun obj_vec_destroy(v: vector<Obj>, _: &mut TxContext) {
        assert!(vector::length(&v) == 1, 0);
        let Obj {id, value} = vector::pop_back(&mut v);
        assert!(value == 42, 0);
        object::delete(id);
        vector::destroy_empty(v);
    }

    public entry fun two_obj_vec_destroy(v: vector<Obj>, _: &mut TxContext) {
        assert!(vector::length(&v) == 2, 0);
        let Obj {id, value} = vector::pop_back(&mut v);
        assert!(value == 42, 0);
        object::delete(id);
        let Obj {id, value} = vector::pop_back(&mut v);
        assert!(value == 7, 0);
        object::delete(id);
        vector::destroy_empty(v);
    }

    public entry fun same_objects(o: Obj, v: vector<Obj>, _: &mut TxContext) {
        let Obj {id, value} = o;
        assert!(value == 42, 0);
        object::delete(id);
        let Obj {id, value} = vector::pop_back(&mut v);
        assert!(value == 42, 0);
        object::delete(id);
        vector::destroy_empty(v);
    }

    public entry fun same_objects_ref(o: &Obj, v: vector<Obj>, _: &mut TxContext) {
        assert!(o.value == 42, 0);
        let Obj {id, value: _} = vector::pop_back(&mut v);
        object::delete(id);
        vector::destroy_empty(v);
    }

    public entry fun child_access(child: Obj, v: vector<Obj>, _: &mut TxContext) {
        let Obj {id, value} = child;
        assert!(value == 42, 0);
        object::delete(id);
        let Obj {id, value} = vector::pop_back(&mut v);
        assert!(value == 42, 0);
        object::delete(id);
        vector::destroy_empty(v);
    }

}

// create an object and pass it as a single element of a vector (success)

//# run Test::M::prim_vec_len --sender A --args vector[7,42]

//# run Test::M::mint --sender A --args 42


// create a parent/child object pair, pass child by-value and parent as a single element of a vector
// to check if authentication works (success)

//# run Test::M::obj_vec_destroy --sender A --args vector[object(108)]

//# run Test::M::mint --sender A --args 42

//# run Test::M::mint_child --sender A --args 42 object(111)

//# run Test::M::child_access --sender A --args object(111) vector[object(113)]


// create an object of one type and try to pass it as a single element of a vector whose elements
// are of different type (failure)

//# run Test::M::mint_another --sender A --args 42

//# run Test::M::obj_vec_destroy --sender A --args vector[object(117)]


// create two objects of different types and try to pass them both as elements of a vector (failure)

//# run Test::M::mint_another --sender A --args 42

//# run Test::M::mint --sender A --args 42

//# run Test::M::two_obj_vec_destroy --sender A --args vector[object(120),object(122)]


// create a shared object and try to pass it as a single element of a vector (failure)

//# run Test::M::mint_shared --sender A --args 42

//# run Test::M::obj_vec_destroy --sender A --args vector[object(125)]


// create an object and pass it both by-value and as element of a vector (failure)

//# run Test::M::mint --sender A --args 42

//# run Test::M::same_objects --sender A --args object(128) vector[object(128)]


// create an object and pass it both by-reference and as element of a vector (failure)

//# run Test::M::mint --sender A --args 42

//# run Test::M::same_objects_ref --sender A --args object(130) vector[object(130)]
