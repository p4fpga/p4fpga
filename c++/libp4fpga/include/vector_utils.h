
#include <boost/iterator/zip_iterator.hpp>
#include <boost/range/iterator_range.hpp>
#include <boost/tuple/tuple.hpp>

namespace FPGA {

template <class C1, class C2>
class Zip {
 public:
  //typedef boost::tuple<typename C1::value_type, typename C2::value_type>
  //value_type;

  typedef boost::iterator_range<
    boost::zip_iterator<boost::tuple<typename C1::const_iterator,
                                     typename C2::const_iterator> > >
  range_type;
};

template <class C1, class C2>
typename Zip<C1, C2>::range_type
MakeZipRange(const C1 &container1, const C2 &container2);

template <class C1, class C2>
typename Zip<C1, C2>::range_type
MakeZipRange(const C1 &container1, const C2 &container2) {
  return boost::make_iterator_range(
      boost::make_zip_iterator(
        boost::make_tuple(container1.begin(), container2.begin())),
      boost::make_zip_iterator(
        boost::make_tuple(container1.end(), container2.end())));
};
}
