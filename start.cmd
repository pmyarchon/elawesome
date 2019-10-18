@echo off
iex -S mix phx.server
if errorlevel 1 pause
