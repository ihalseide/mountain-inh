-- Do testing for "mountain-inh.lua"
require 'mountain-inh'

function test_member()
    print("Testing member()")
    t = {'apple', 3, -12.2, 'Bob'}
    assert(true == member('apple', t), "apple should be a member of t")
    assert(false == member('orange', t), "orange should not be a member of t")
    assert(false == member({1}, {'a', {1}}), "table {1} should not be a member of {'a', {1}}")
end


function test_isInteger()
    print("Testing isInteger()")
    assert(true == isInteger(3), "3 should be an integer")
    assert(false == isInteger(3.14), "3.14 should not be an integer")
    for i = -12, 12 do
        assert(true == isInteger(i), i .. " should be an integer")
    end
    assert(false == isInteger(true))
    assert(false == isInteger(false))
    assert(false == isInteger("string"))
    assert(false == isInteger({1, 2, 3}))
end


function test_tableEqual()
    print("Testing tableEqual()")
    assert(true == tableEqual({}, {}))
    assert(true == tableEqual({1}, {1}))
    assert(true == tableEqual({1, 2}, {1, 2}))
    assert(false == tableEqual({}, {1}))
    assert(false == tableEqual({2}, {1}))
    assert(true == tableEqual({1, '2'}, {1, '2'}))
    assert(false == tableEqual({1, '2'}, {1, 2}))
end


function test_reverseTable()
    print("Testing reverseTable()")
    assert(true == tableEqual({3, 2, 1}, reverseTable({1, 2, 3})))
    assert(true == tableEqual({2, 1}, reverseTable({1, 2})))
    assert(true == tableEqual({1}, reverseTable({1})))
    assert(true == tableEqual({}, reverseTable({})))
end


function test_isPrime()
    print("Testing isPrime()")
    comp = {0, 4, 6, 8, 9, 10, 12, 14, 15, 16, 18, 20}
    prim = {2, 3, 5, 7, 11, 13, 17, 19}
    for _, c in ipairs(comp) do
        assert(false == isPrime(c), c .. " should not be a prime number")
    end
    for _, p in ipairs(prim) do
        assert(true == isPrime(p), p .. " should be a prime number")
    end
end


function test_Sparse2D()
    print("Testing Sparse2D")
    local s = Sparse2D.new()
    assert(true == tableEqual({}, s), "s should be an empty table")
    -- Make sure the default value is nil
    assert(nil == s[{0, 0}])
    -- Test assignment at a specific location
    s[{0, 0}] = 1
    assert(1 == s[{0, 0}])
    -- Check that a different location is still nil
    assert(nil == s[{1, 1}])
    -- Make sure non-table keys are not allowed
    s['i'] = 3
    assert(nil == s['i'])
    -- Test re-assignment
    s[{0, 0}] = 'new!'
    assert('new!' == s[{0, 0}])
end


print("Testing...")
test_member()
test_isInteger()
test_isPrime()
test_tableEqual()
test_reverseTable()
test_Sparse2D()
print("All tests passed!")