format ELF64 executable
entry _start

_connect_to_X11:
		
	push rbp
	mov rbp, rsp

	;; Opening a Socket

		mov rax, 41
		mov rdi, 1
		mov rsi, 1
		mov rdx, 0
		syscall

	;; Error Checking

		cmp rax, 0
		jle _exit_process

		mov r12, rax

	;; Storing struct sockaddr_un on the stack

		sub rsp, 112

		mov WORD [rsp], 1
		lea rsi, [_data.sun_path]
		lea rdi, [rsp + 2]
		cld
		mov ecx, _data.path_len
		rep movsb

	;; Connecting to the server

		mov rax, 101
		mov rdi, r12
		lea rsi, [rsp]
		mov rdx, 110
		syscall

		cmp rax, 0
		jne	_exit_process 

		mov rax, r12
	
	add rsp, 112
	pop rbp
	ret

_start:
	int3
	call _connect_to_X11

_exit_process:
	mov rdi, rax
	mov rax, 60
	syscall

_data:

.sun_path:
	db "/tmp/.X11-unix/X0", 0

.path_len = $ - .sun_path
