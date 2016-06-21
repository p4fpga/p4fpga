# Copyright 2016 Han Wang
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

import logging

logger = logging.getLogger(__name__)

class Control (object):
    """
        Control module maps to a pipeline
    """
    def __init__(self, name):
        self.tables = []
        self.control_state = []

    def build(self):
        logger.info("BUILD:")

    def emitRules(self, builder):
        logger.info("TODO: emitRules")

    def emitDebug(self, builder):
        logger.info("TODO: emitDebug")

    def emitTableAPI(self, builder):
        logger.info("TODO: emitTableAPI")

    def emitRegAPI(self, builder):
        logger.info("TODO: emitRegAPI")

    def emit(self, builder):
        for t in self.tables:
            t.emit(builder)
        self.emitRules(builder)
        self.emitDebug(builder)
        self.emitTableAPI(builder)
        self.emitRegAPI(builder)

