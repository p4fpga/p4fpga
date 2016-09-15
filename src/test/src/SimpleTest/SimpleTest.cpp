
#include "gtest/gtest.h"

#include <iostream>
#include <memory>

using namespace std;

class SimpleTest : public ::testing::Test
{
public:
    SimpleTest() {}
protected:
    virtual void SetUp()
    {
    }
    virtual void TearDown()
    {
    }
};

TEST_F(SimpleTest, Example)
{
    EXPECT_EQ(false, true);
}





