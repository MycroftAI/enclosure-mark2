from logging import (
    basicConfig,
    getLogger,
    DEBUG,
    Formatter,
    StreamHandler
)
from os.path import getmtime, exists
from time import time, sleep
from subprocess import call
import sys

def configure_logger():
    logger = getLogger()
    logger.level = DEBUG
    formatter = Formatter(
        '{asctime} | {levelname:8} | {process:5} | {name} | {message}',
        style='{'
    )
    formatter.default_msec_format = '%s.%03d'
    handler = StreamHandler(sys.stdout)
    handler.setLevel(DEBUG)
    handler.setFormatter(formatter)
    logger.addHandler(handler)

LOG = getLogger(__name__)

class MicrophoneMonitor:
    def __init__(self):
        self.mic_level_path = '/ramdisk/mycroft/ipc/mic_level'
        self.restart_voice_command = (
                '/home/pi/mycroft-core/start-mycroft.sh',
                'voice',
                'restart'
            )
        self.interval = 60
        self.startup_delay = 60

    def running(self):
        """
        Consider the mic input to be working if the mic_level file has been
        modified in the last minute.
        """
        return (
            exists(self.mic_level_path) and 
            time() < getmtime(self.mic_level_path) + 60
        )

    def muted(self):
        """
        Read muted state from mic level file.
        It looks like 'muted=0' at the end of the file.
        """ 
        with open(self.mic_level_path) as f:
            text = f.read()
            muted = int(text.split('=')[-1])
        return muted

    def restart_voice_process(self):
        call(self.restart_voice_command)

    def run(self):
        while True:
            try:
                sleep(self.interval)
                if not self.running() and not self.muted():
                    LOG.info('Mic seems to be frozen! Restarting voice process...')
                    self.restart_voice_process()
                    sleep(self.startup_delay)  # Give startup some extra time to complete
            except Exception as e:
                LOG.exception('Mic check failed.')

if __name__ == '__main__':
    configure_logger()
    mic_monitor = MicrophoneMonitor()
    mic_monitor.run()

