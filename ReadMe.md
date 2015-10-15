## Synopsis

the purpose of this PowerShell scripting tool is to provide an easy way for Dynamics GP admins to unlock user accounts
without having to go through all the manual steps of resetting their passwords in SQL, unlocking them in SQL, logging
into GP and resetting their passwords, etc..

the tool runs under the context of the user that is launching the script, so that user will need suitable permissions 
on the SQL instance being accessed. It's a simple tool, it can probably be improved a lot or refined. hope that someone 
may find that it saves them some time and is useful. 

## Code Example

Run this code either standalone such as .\GP-UnlockUser.ps1 or from within your PowerShell "launch pad" (another thing I want to post up here soon).

## Motivation

One of the first admin tasks that I wanted to make easier to perform was the unlocking of Dynamics GP user accounts. If you’ve dealt with this before, you know what a PITA it is to simply unlock someone’s GP account if they entered the wrong password too many times. This is a simple attempt at avoiding the headache of having to…

Login to SQL Management Studio
Reset the password for the user’s SQL login.
Unlock the user’s SQL login.
Launch Dynamics GP, login, and reset their password (again) within GP.
Instead, you can use this script and do the following…

Launch this script.
Choose the user in the drop-down, and click a button.
Go back and work on something else :-)

## Installation

This is just a stand-alone PowerShell script.

## API Reference

No API here. <sounds of crickets>

## Tests

No testing info here. <sounds of crickets>

## Contributors

Just a solo script project by moi, Greg Besso. Hi there :-)

## License

Copyright (c) 2015 Greg Besso

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.