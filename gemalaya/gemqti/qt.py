import concurrent.futures
import functools

from PySide6.QtCore import Slot


threadpool = concurrent.futures.ThreadPoolExecutor(max_workers=16)


def tSlot(*args, **kws):
    def got_result(sig, sige, future):
        try:
            result = future.result()

            if isinstance(result, tuple):
                sig.emit(*result)
            else:
                sig.emit(result)
        except Exception as err:
            sige.emit(str(err))

    def outer_decorator(fn):
        @Slot(*args)
        @functools.wraps(fn)
        def wrapper(*args, **kwargs):
            sig = getattr(args[0], kws.get('sigSuccess'))

            opt = kws.get('sigError')
            sige = getattr(args[0], opt) if opt else None

            f = threadpool.submit(fn, *args)
            f.add_done_callback(functools.partial(got_result, sig, sige))

        return wrapper
    return outer_decorator
