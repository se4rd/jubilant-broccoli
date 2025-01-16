format ELF64 executable
entry _start

_connect_to_X11:
		
	push rbp
	mov rbp, rsp
	sub rsp, 112

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

		mov WORD [rsp], 1
		lea rsi, [_data.sun_path]
		lea rdi, [rsp + 2]
		cld
		mov ecx, _data.path_len
		rep movsb

	;; Connecting to the server

		mov rax, 42
		mov rdi, r12
		lea rsi, [rsp]
		mov rdx, 110
		syscall

		cmp rax, 0
		jne	_exit_process 

	add rsp, 112
	pop rbp
	ret

_send_handshake_to_X11:

	push rbp
	mov rbp, rsp
	sub rsp, 32768

	;; Create structure for handshake

		mov BYTE [rsp + 0], 'l'
		mov WORD [rsp + 2], 11

	;; Send handshake to the server

		mov rax, 1
		mov rdi, r12
		lea rsi, [rsp]
		mov rdx, 12
		syscall

		cmp rax, 12
		jnz _exit_process

	;; Read the server response (8 bytes)

		mov rax, 0
		mov rdi, r12
		lea rsi, [rsp]
		mov rdx, 8
		syscall

		cmp rax, 8
		jnz _exit_process

	;; Check if server sent 'success' (first byte must be 1)

		cmp BYTE [rsp], 1
		jnz _exit_process

	;; Read the rest of the server response

		mov rax, 0
		mov rdi, r12
		mov rsi, rsp
		mov rdx, 32768
		syscall

		cmp rax, 0
		jle _exit_process

	;; Set id_base 

		mov edx, DWORD [rsp + 4]
		mov DWORD [_data.id_base], edx

	;; Set id_mask

		mov edx, DWORD [rsp + 8]
		mov DWORD [_data.id_mask], edx

	;; Pointer that will skip over some data

		mov rdi, rsp

	;; Vendor length

		mov cx, WORD [rsp + 16]
		movzx rcx, cx

	;; Number of formats | sizeof(each format) == 8

		mov al, BYTE [rsp + 21]
		movzx rax, al
		imul rax, 8

	;; Skip connection setup and vendor information

		add rdi, 32
		add rdi, rcx

	;; Skip over padding

		add rdi, 3
		add rdi, -4

	;; Skip over the format information

		add rdi, rax

	;; Store (Return) the window root id

		mov eax, DWORD [rdi]

	;; Set root_visual_id

		mov edx, DWORD [rdi + 32]
		mov DWORD [_data.root_visual_id], edx

	add rsp, 32768
	pop rbp
	ret

_generate_next_id:

	push rbp
	mov rbp, rsp

	;; Load id

		mov eax, DWORD [_data.id]

	;; Load base and mask id

		mov ebx, DWORD [_data.id_base]
		mov ecx, DWORD [_data.id_mask]

	;; (id & id_mask) | id_base

		and eax, ecx
		or eax, ebx

	;; Increment id

		add DWORD [_data.id], 1

	pop rbp
	ret

_start:
	call _connect_to_X11
	call _send_handshake_to_X11

_exit_process:
	mov rdi, rax
	mov rax, 60
	syscall

_data:

.sun_path:
	db "/tmp/.X11-unix/X0", 0

.path_len = $ - .sun_path

.id:
	dd 0

.id_base:
	dd 0
	
.id_mask:
	dd 0

.root_visual_id:
	dd 0

